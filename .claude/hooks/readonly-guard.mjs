#!/usr/bin/env node
// PreToolUse hook for read-only subagents (see .claude/agents/). Blocks Bash
// commands that would change the repo, the filesystem or installed packages.
// It is a guardrail against accidents, not a sandbox: interpreters such as
// `node -e` stay allowed because reviewers use them to probe behavior.

import { readFileSync, realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";

const GIT_READ = new Set([
  "blame", "cat-file", "describe", "diff", "for-each-ref", "grep", "log",
  "ls-files", "ls-tree", "merge-base", "name-rev", "rev-list", "rev-parse",
  "shortlog", "show", "show-ref", "status",
]);
// Subcommands that only read when called in their listing form.
const GIT_LISTING = {
  branch: (args) => args.every((a) => /^(-a|-r|-v|-vv|--all|--remotes|--list|--show-current|--contains|--merged|--no-merged|--sort=.*|--format=.*|--no-color|--color.*)$/.test(a)),
  tag: (args) => args.length === 0 || args[0] === "-l" || args[0] === "--list",
  stash: (args) => args[0] === "list" || args[0] === "show",
  remote: (args) => args.length === 0 || ["-v", "show", "get-url"].includes(args[0]),
  config: (args) => args.some((a) => /^(--get.*|--list|-l)$/.test(a)),
  worktree: (args) => args[0] === "list",
  reflog: (args) => args.length === 0 || args[0] === "show" || args[0].startsWith("-"),
};
const GH_READ = /^(pr (view|diff|list|checks|status)|issue (view|list|status)|run (view|list)|repo view|release (view|list)|search \w+)$/;
// Scratch files (repro scripts, outputs) may be written under these
// absolute temporary directories, never inside the repo under review.
const TEMP_PATH = /^(?!.*(^|\/)\.\.(\/|$))(\/private)?(\/tmp|\/var\/folders)\//;
// File commands allowed only when the paths they write are temporary:
// every path for those that remove or move, the destination for copies.
const WRITES_ALL_PATHS = new Set(["rm", "rmdir", "mv", "touch", "mkdir", "truncate", "tee"]);
const WRITES_LAST_PATH = new Set(["cp", "ln"]);
const MUTATING = new Set(["chmod", "chown", "dd", "install", "patch", "eval", "sudo"]);
const SHELLS = new Set(["sh", "bash", "zsh", "fish", "dash"]);
const PACKAGE_WRITES = {
  npm: /^(i|install|ci|add|uninstall|remove|rm|un|update|up|link|publish)$/,
  pnpm: /^(i|install|add|remove|rm|update|up|link|publish)$/,
  yarn: /^(install|add|remove|upgrade|link|publish)$/,
  bun: /^(i|install|add|remove|rm|update|link|publish)$/,
  brew: /^(install|uninstall|reinstall|upgrade|update|remove|rm|link|unlink|tap|untap)$/,
  pip: /^(install|uninstall)$/,
  pip3: /^(install|uninstall)$/,
  gem: /^(install|uninstall|update)$/,
  cargo: /^(install|uninstall|add|remove|update|publish)$/,
  go: /^(install|get|mod)$/,
};
const SAFE_REDIRECT = /^(\/dev\/(null|stdout|stderr)$|&\d+$)/;

// Split a command line into simple commands, honoring quotes. Returns the
// commands (token arrays), redirection targets and command substitutions.
function parse(line) {
  const commands = [[]];
  const redirects = [];
  const nested = [];
  let token = null;
  const push = () => {
    if (token !== null) commands.at(-1).push(token);
    token = null;
  };
  const readUntilClose = (start, open, close) => {
    let depth = 1;
    let i = start;
    for (; i < line.length && depth > 0; i++) {
      if (line[i] === open) depth++;
      else if (line[i] === close) depth--;
    }
    nested.push(line.slice(start, i - 1));
    return i - 1;
  };

  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (c === "'") {
      const end = line.indexOf("'", i + 1);
      token = (token ?? "") + line.slice(i + 1, end === -1 ? line.length : end);
      i = end === -1 ? line.length : end;
    } else if (c === '"') {
      let value = "";
      for (i++; i < line.length && line[i] !== '"'; i++) {
        if (line[i] === "\\" && i + 1 < line.length) value += line[++i];
        else if (line[i] === "$" && line[i + 1] === "(") i = readUntilClose(i + 2, "(", ")");
        else if (line[i] === "`") {
          const end = line.indexOf("`", i + 1);
          nested.push(line.slice(i + 1, end === -1 ? line.length : end));
          i = end === -1 ? line.length : end;
        } else value += line[i];
      }
      token = (token ?? "") + value;
    } else if (c === "\\" && i + 1 < line.length) {
      token = (token ?? "") + line[++i];
    } else if ((c === "$" || c === "<" || c === ">") && line[i + 1] === "(") {
      i = readUntilClose(i + 2, "(", ")");
      token = (token ?? "") + "SUBST";
    } else if (c === "`") {
      const end = line.indexOf("`", i + 1);
      nested.push(line.slice(i + 1, end === -1 ? line.length : end));
      i = end === -1 ? line.length : end;
      token = (token ?? "") + "SUBST";
    } else if (c === "<" && line[i + 1] === "<" && line[i + 2] !== "<") {
      // Heredoc: its body is data for the command, not more commands.
      push();
      let j = i + 2;
      const strip = line[j] === "-";
      if (strip) j++;
      while (line[j] === " " || line[j] === "\t") j++;
      let delimiter = "";
      while (j < line.length && !/[\s;&|<>()]/.test(line[j])) delimiter += line[j++];
      delimiter = delimiter.replace(/['"\\]/g, "");
      const bodyStart = line.indexOf("\n", j);
      if (bodyStart === -1) {
        i = j - 1;
        continue;
      }
      // Finish parsing the rest of this line, then skip the body.
      const rest = parse(line.slice(j, bodyStart));
      commands.at(-1).push(...(rest.commands[0] ?? []));
      commands.push(...rest.commands.slice(1));
      redirects.push(...rest.redirects);
      nested.push(...rest.nested);
      let k = bodyStart + 1;
      while (k < line.length) {
        const end = line.indexOf("\n", k);
        const bodyLine = line.slice(k, end === -1 ? line.length : end);
        k = end === -1 ? line.length : end + 1;
        if ((strip ? bodyLine.replace(/^\t+/, "") : bodyLine) === delimiter) break;
      }
      commands.push([]);
      i = k - 1;
    } else if (c === ">") {
      // A digit or & right before > is part of the operator (2>, &>).
      if (token !== null && /^(\d|&)$/.test(token)) token = null;
      push();
      if (line[i + 1] === ">") i++;
      if (line[i + 1] === "|") i++;
      let j = i + 1;
      while (line[j] === " " || line[j] === "\t") j++;
      let target = "";
      while (j < line.length && !/[\s;&|<>()]/.test(line[j])) target += line[j++];
      if (target === "" && line[j] === "&") {
        target = "&";
        for (j++; /\d/.test(line[j] ?? ""); j++) target += line[j];
      }
      redirects.push(target);
      i = j - 1;
    } else if (";&|\n".includes(c) || c === "(" || c === ")") {
      push();
      if (commands.at(-1).length > 0) commands.push([]);
    } else if (c === " " || c === "\t") {
      push();
    } else {
      token = (token ?? "") + c;
    }
  }
  push();
  return { commands: commands.filter((cmd) => cmd.length > 0), redirects, nested };
}

function gitReason(args) {
  let i = 0;
  while (i < args.length && args[i].startsWith("-")) {
    // Global options; -C and -c take a separate value.
    i += args[i] === "-C" || args[i] === "-c" ? 2 : 1;
  }
  const sub = args[i];
  const rest = args.slice(i + 1);
  if (sub === undefined || GIT_READ.has(sub)) return null;
  if (GIT_LISTING[sub]?.(rest)) return null;
  return `git ${sub} is not read-only`;
}

function commandReason(tokens) {
  let i = 0;
  // Leading variable assignments and transparent wrappers.
  while (i < tokens.length && (/^\w+=/.test(tokens[i]) || ["env", "command", "nohup", "time"].includes(tokens[i]))) i++;
  const [cmd, ...args] = tokens.slice(i);
  if (cmd === undefined) return null;
  const name = cmd.split("/").at(-1);

  if (MUTATING.has(name)) return `${name} modifies files or privileges`;
  if (WRITES_ALL_PATHS.has(name) || WRITES_LAST_PATH.has(name)) {
    const paths = args.filter((a) => !a.startsWith("-"));
    const written = WRITES_LAST_PATH.has(name) ? paths.slice(-1) : paths;
    if (written.length === 0 || !written.every((p) => TEMP_PATH.test(p))) {
      return `${name} modifies files outside an absolute temporary directory`;
    }
    return null;
  }
  if (SHELLS.has(name) && (args.includes("-c") || !args.some((a) => !a.startsWith("-")))) {
    return "nested shells are not inspected; run the command directly";
  }
  if (name === "git") return gitReason(args);
  if (name === "gh") {
    if (args[0] === "api") {
      const method = args.findIndex((a) => a === "-X" || a === "--method");
      const writes = args.some((a) => /^(-f|-F|--field|--raw-field|--input)$/.test(a));
      return writes || (method !== -1 && args[method + 1]?.toUpperCase() !== "GET") ? "gh api writes" : null;
    }
    return GH_READ.test(args.slice(0, 2).join(" ")) ? null : `gh ${args.slice(0, 2).join(" ")} is not read-only`;
  }
  if (PACKAGE_WRITES[name]?.test(args[0] ?? "")) return `${name} ${args[0]} changes installed packages`;
  if ((name === "sed" || name === "perl") && args.some((a) => /^(-i.*|--in-place.*|-pi.*)$/.test(a))) {
    return `${name} in-place editing modifies files`;
  }
  if (name === "find") {
    if (args.includes("-delete")) return "find -delete removes files";
    const exec = args.findIndex((a) => /^-(exec|execdir|ok|okdir)$/.test(a));
    if (exec !== -1) {
      const end = args.findIndex((a, k) => k > exec && (a === ";" || a === "+"));
      return commandReason(args.slice(exec + 1, end === -1 ? undefined : end));
    }
  }
  if (name === "xargs") {
    const start = args.findIndex((a) => !a.startsWith("-"));
    return start === -1 ? null : commandReason(args.slice(start));
  }
  return null;
}

export function blockedReason(line) {
  const { commands, redirects, nested } = parse(line);
  const unsafe = redirects.find((target) => !SAFE_REDIRECT.test(target) && !TEMP_PATH.test(target));
  if (unsafe !== undefined) return `output redirection to ${unsafe || "a file"} writes outside an absolute temporary directory`;
  for (const tokens of commands) {
    const reason = commandReason(tokens);
    if (reason) return reason;
  }
  for (const inner of nested) {
    const reason = blockedReason(inner);
    if (reason) return reason;
  }
  return null;
}

const isMain = process.argv[1] && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  let command = "";
  try {
    command = JSON.parse(readFileSync(0, "utf8")).tool_input?.command ?? "";
  } catch {
    process.exit(0);
  }
  const reason = blockedReason(command);
  if (reason) {
    process.stderr.write(`Blocked: ${reason}. This agent is read-only; report the finding instead of changing anything.\n`);
    process.exit(2);
  }
}

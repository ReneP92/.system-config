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
const WRITES_ALL_PATHS = new Set(["rm", "rmdir", "unlink", "mv", "touch", "mkdir", "truncate", "tee"]);
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
    if (c === "$" && line[i + 1] === "'") {
      // ANSI-C quoting, as in $'a\nb', where backslash escapes are decoded.
      let value = "";
      for (i += 2; i < line.length && line[i] !== "'"; i++) {
        if (line[i] !== "\\" || i + 1 >= line.length) {
          value += line[i];
          continue;
        }
        const e = line[++i];
        const hex = e === "x" && /^[0-9a-fA-F]{1,2}/.exec(line.slice(i + 1));
        const octal = /[0-7]/.test(e) && /^[0-7]{1,3}/.exec(line.slice(i));
        if (hex) {
          value += String.fromCharCode(parseInt(hex[0], 16));
          i += hex[0].length;
        } else if (octal) {
          value += String.fromCharCode(parseInt(octal[0], 8));
          i += octal[0].length - 1;
        } else value += { n: "\n", t: "\t", r: "\r", a: "\x07", b: "\b", e: "\x1b", E: "\x1b", f: "\f", v: "\v" }[e] ?? e;
      }
      token = (token ?? "") + value;
    } else if (c === "'") {
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

// Option words before "--". A short cluster is cut after its first letter in
// `values.short` (an option that takes a value), and a value given as the next
// argument is skipped, as it is for the long options in `values.long`.
function optionWords(args, values = {}) {
  const short = values.short ?? "";
  const long = values.long ?? [];
  const words = [];
  for (let k = 0; k < args.length && args[k] !== "--"; k++) {
    const a = args[k];
    if (!/^-./.test(a)) continue;
    if (a.startsWith("--")) {
      words.push(a);
      if (long.includes(a)) k++;
      continue;
    }
    const cut = [...a.slice(1)].findIndex((c) => short.includes(c));
    words.push(cut === -1 ? a : a.slice(0, cut + 2));
    if (cut !== -1 && cut + 2 === a.length) k++;
  }
  return words;
}

// Whether a short option word such as -ro sets one of the given letters.
function hasShortFlag(words, letters) {
  return words.some((w) => /^-[^-]/.test(w) && [...w.slice(1)].some((c) => letters.includes(c)));
}

// A path a command may write: a temporary file, or standard output or error.
const writable = (path) => TEMP_PATH.test(path) || SAFE_REDIRECT.test(path) || path === "-";

const GIT_GREP_VALUES = {
  short: "efABCm",
  long: ["--max-depth", "--max-count", "--threads", "--after-context", "--before-context", "--context"],
};
const GIT_LOG_VALUES = { short: "SG", long: ["--grep", "--author", "--committer"] };
// Config keys whose values git runs as commands.
const GIT_COMMAND_CONFIG = /^(alias\.|core\.(fsmonitor|pager|sshcommand|editor|hookspath)|diff\.external|sequence\.editor|filter\.|gpg\.|.*\.(textconv|command|cmd|program|helper)$)/i;

function gitReason(args) {
  let i = 0;
  while (i < args.length && args[i].startsWith("-")) {
    const config = args[i] === "-c" ? args[i + 1] : args[i].startsWith("--config-env") ? (args[i].split("=")[1] ?? args[i + 1]) : null;
    if (config && GIT_COMMAND_CONFIG.test(config)) return `git -c ${config.split("=")[0]} runs a command`;
    // Global options; -C, -c and --config-env take a separate value.
    i += ["-C", "-c", "--config-env"].includes(args[i]) ? 2 : 1;
  }
  const sub = args[i];
  const rest = args.slice(i + 1);
  const words = optionWords(rest, sub === "grep" ? GIT_GREP_VALUES : GIT_LOG_VALUES);
  if (words.some((w) => w.startsWith("--out") && !w.startsWith("--output-indicator"))) {
    return `git ${sub} --output writes a file`;
  }
  if (sub === "grep" && (hasShortFlag(words, "O") || words.some((w) => w.startsWith("--op")))) {
    return "git grep -O runs a command";
  }
  if (sub === undefined || GIT_READ.has(sub)) return null;
  if (GIT_LISTING[sub]?.(rest)) return null;
  return `git ${sub} is not read-only`;
}

// Files a sed script writes with w, W or the s///w flag, or null when it runs
// commands with e or the s///e flag.
function sedWrites(script) {
  const files = [];
  let i = 0;
  // A bracket expression such as [/] or [[:alpha:]] in a regex, where the
  // delimiter is an ordinary character.
  const skipBracket = () => {
    i++;
    if (script[i] === "^") i++;
    if (script[i] === "]") i++;
    while (i < script.length && script[i] !== "]") {
      if (script[i] === "[" && ":=.".includes(script[i + 1] ?? "")) {
        const close = script.indexOf(script[i + 1] + "]", i + 2);
        i = close === -1 ? script.length : close + 2;
      } else i++;
    }
    i++;
  };
  const skipDelimited = (regex) => {
    const delimiter = script[i++];
    while (i < script.length && script[i] !== delimiter) {
      if (script[i] === "\\") i += 2;
      else if (regex && script[i] === "[") skipBracket();
      else i++;
    }
    i++;
  };
  const restOfLine = () => {
    const end = script.indexOf("\n", i);
    const text = script.slice(i, end === -1 ? script.length : end);
    i = end === -1 ? script.length : end;
    return text.trim();
  };
  while (i < script.length) {
    const c = script[i];
    // Separators, blocks, negation and addresses (lines, $, steps, ranges).
    if (/[\s;{}!\d$,~+]/.test(c)) i++;
    else if (c === "#") restOfLine();
    else if (c === "/") skipDelimited(true);
    else if (c === "\\") {
      i++;
      skipDelimited(true);
    } else {
      i++;
      if (c === "s" || c === "y") {
        skipDelimited(c === "s");
        i--;
        skipDelimited(false);
        while (c === "s" && i < script.length && !";\n}#".includes(script[i])) {
          if (script[i] === "e") return null;
          if (script[i] === "w") {
            i++;
            files.push(restOfLine());
          } else i++;
        }
      } else if (c === "w" || c === "W") files.push(restOfLine());
      else if (c === "e") return null;
      else if ("aicrR".includes(c)) {
        // Text and file name arguments run to the end of the line, and a
        // trailing backslash continues the text onto the next line.
        while (restOfLine().endsWith("\\") && i < script.length) i++;
      } else if ("btT:".includes(c)) {
        while (i < script.length && !";\n".includes(script[i])) i++;
      }
    }
  }
  return files;
}

function sedReason(args) {
  const scripts = [];
  const operands = [];
  // GNU sed accepts any unambiguous prefix of a long option.
  const isLong = (a, name, min) => {
    const given = a.slice(2).split("=")[0];
    return given.length >= min && name.startsWith(given);
  };
  for (let k = 0; k < args.length; k++) {
    const a = args[k];
    if (a === "--") {
      operands.push(...args.slice(k + 1));
      break;
    }
    if (a.startsWith("--")) {
      if (isLong(a, "in-place", 1)) return "sed in-place editing modifies files";
      if (isLong(a, "file", 2)) return "sed -f scripts are not inspected";
      if (isLong(a, "expression", 1)) scripts.push(a.includes("=") ? a.slice(a.indexOf("=") + 1) : (args[++k] ?? ""));
      else if (isLong(a, "line-length", 1) && !a.includes("=")) k++;
    } else if (a.length > 1 && a.startsWith("-")) {
      for (let j = 1; j < a.length; j++) {
        if ("iI".includes(a[j])) return "sed in-place editing modifies files";
        if (a[j] === "f") return "sed -f scripts are not inspected";
        if (a[j] === "e") {
          scripts.push(a.slice(j + 1) || (args[++k] ?? ""));
          break;
        }
        // GNU -l takes a line length; macOS -l takes no value.
        if (a[j] === "l" && /^\d+$/.test(a.slice(j + 1) || (args[k + 1] ?? ""))) {
          if (j + 1 === a.length) k++;
          break;
        }
      }
    } else operands.push(a);
  }
  if (scripts.length === 0 && operands.length > 0) scripts.push(operands[0]);
  // sed implementations differ on whether text continues from one -e script
  // into the next, so check the scripts both joined and one by one.
  const writes = [scripts.join("\n"), ...scripts].map(sedWrites);
  return writes.some((files) => files === null || !files.every(writable)) ? "sed writes files or runs commands" : null;
}

// Commands that run the rest of their arguments, with their options that take
// a separate value. timeout also takes a duration before the command.
const WRAPPERS = {
  env: ["-u", "-C", "--unset", "--chdir"],
  command: [],
  exec: ["-a"],
  nohup: [],
  time: [],
  nice: ["-n", "--adjustment"],
  timeout: ["-s", "-k", "--signal", "--kill-after"],
  stdbuf: ["-i", "-o", "-e"],
};
// Variables that make git or rg run a command or read another config.
const COMMAND_ENV = /^(GIT_EXTERNAL_DIFF|GIT_SSH|GIT_SSH_COMMAND|GIT_PAGER|GIT_EDITOR|GIT_CONFIG\w*|RIPGREP_CONFIG_PATH)=/;
const XARGS_VALUES = ["-n", "-I", "-L", "-P", "-s", "-E", "-d", "-a", "-J", "-R", "-S", "--max-args", "--max-procs", "--max-chars", "--delimiter", "--arg-file"];
const RG_VALUES = {
  short: "efgtTmABCMrj",
  long: ["--regexp", "--file", "--glob", "--iglob", "--type", "--type-not", "--max-count", "--replace", "--context", "--after-context", "--before-context", "--max-columns", "--max-depth", "--threads", "--pre-glob"],
};
const COMPRESSORS = new Set(["gzip", "gunzip", "bzip2", "bunzip2", "xz", "unxz", "zstd", "unzstd"]);
const CURL_VALUES = "AbcCdDeEFhHKmoPQrtTuUwxXyYz";
const CURL_WRITES = /^--(output|dump-header|cookie-jar|output-dir|trace|trace-ascii|libcurl|etag-save|stderr)(=|$)/;
// Flags that make linters, formatters and test runners rewrite files.
const REWRITE_FLAGS = new Set(["--fix", "--write", "--update-snapshots", "--updateSnapshot"]);
// Names the guard inspects, so the g-prefixed GNU builds Homebrew installs
// (gsed, gsort, grm) are inspected the same way.
const INSPECTED = new Set([
  ...WRITES_ALL_PATHS, ...WRITES_LAST_PATH, ...MUTATING, ...Object.keys(WRAPPERS), ...COMPRESSORS,
  "sed", "sort", "find", "xargs", "uniq", "tar",
]);

function toolName(cmd) {
  const name = cmd.split("/").at(-1);
  return name.startsWith("g") && INSPECTED.has(name.slice(1)) ? name.slice(1) : name;
}

function curlReason(args) {
  for (let k = 0; k < args.length; k++) {
    const a = args[k];
    if (/^--(remote-name|remote-name-all|remote-header-name)$/.test(a)) return "curl -O writes a file";
    if (CURL_WRITES.test(a)) {
      const target = a.includes("=") ? a.slice(a.indexOf("=") + 1) : args[++k];
      if (!writable(target ?? "")) return `curl ${a.split("=")[0]} writes a file`;
    } else if (/^-[^-]/.test(a)) {
      for (let j = 1; j < a.length; j++) {
        if ("OJ".includes(a[j])) return "curl -O writes a file";
        if (!CURL_VALUES.includes(a[j])) continue;
        const value = a.slice(j + 1) || args[++k];
        if ("oDc".includes(a[j]) && !writable(value ?? "")) return `curl -${a[j]} writes a file`;
        break;
      }
    }
  }
  return null;
}

function commandReason(tokens) {
  if (tokens.some((t) => COMMAND_ENV.test(t))) return `${tokens.find((t) => COMMAND_ENV.test(t)).split("=")[0]} makes git or rg run a command`;
  let i = 0;
  // Leading variable assignments and wrappers that run the rest.
  while (i < tokens.length) {
    if (/^\w+=/.test(tokens[i])) {
      i++;
      continue;
    }
    const wrapper = toolName(tokens[i]);
    const values = WRAPPERS[wrapper];
    if (!values) break;
    for (i++; tokens[i]?.startsWith("-"); i += values.includes(tokens[i]) ? 2 : 1) {
      if (wrapper === "command" && /^-[vV]/.test(tokens[i])) return null;
      if (wrapper === "env" && (tokens[i].startsWith("-S") || tokens[i].startsWith("--split-string"))) {
        const split = tokens[i].length > 2 && tokens[i].startsWith("-S") ? tokens[i].slice(2) : tokens[i].includes("=") ? tokens[i].split("=").slice(1).join("=") : tokens[i + 1];
        return blockedReason(split ?? "");
      }
    }
    if (wrapper === "timeout") i++;
  }
  const [cmd, ...args] = tokens.slice(i);
  if (cmd === undefined) return null;
  const name = toolName(cmd);

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
  if (args.some((a) => REWRITE_FLAGS.has(a.split("=")[0]))) return `${args.find((a) => REWRITE_FLAGS.has(a.split("=")[0]))} rewrites files`;
  if ([cmd, ...args].some((a) => /(^|\/)(vitest|jest)$/.test(a)) && args.includes("-u")) return "-u updates test snapshots";
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
  if (name === "sed") return sedReason(args);
  // -i may follow other switches in a cluster such as -0pi, but not a switch
  // whose value runs to the end of the cluster, such as -e or -M.
  if (name === "perl" && args.some((a) => /^-[^-eEMmIxdDC]*i/.test(a))) return "perl in-place editing modifies files";
  if (name === "rg") {
    const runs = optionWords(args, RG_VALUES).find((w) => /^--(pre|hostname-bin)(=|$)/.test(w));
    if (runs) return `rg ${runs.split("=")[0]} runs a command`;
  }
  if (name === "tree") {
    const words = optionWords(args, { short: "LPIHT" });
    if (hasShortFlag(words, "o")) return "tree -o writes a file";
    if (hasShortFlag(words, "R")) return "tree -R writes HTML files";
  }
  if (name === "sort") {
    const words = optionWords(args, {
      short: "kotST",
      long: ["--key", "--field-separator", "--buffer-size", "--temporary-directory", "--parallel", "--batch-size", "--sort", "--random-source", "--files0-from"],
    });
    if (hasShortFlag(words, "o") || words.some((w) => w.startsWith("--o"))) return "sort -o writes a file";
    if (words.some((w) => w.startsWith("--com"))) return "sort --compress-program runs a command";
  }
  if (name === "file") {
    const words = optionWords(args, { short: "emfFP" });
    if (hasShortFlag(words, "C") || words.some((w) => w.startsWith("--comp"))) return "file -C writes a file";
  }
  if (name === "uniq") {
    const operands = args.filter((a, k) => !a.startsWith("-") && !["-f", "-s", "-w"].includes(args[k - 1]));
    if (operands.length > 1 && !writable(operands[1])) return "uniq writes its output file";
  }
  if (COMPRESSORS.has(name)) {
    const words = optionWords(args);
    const reads = hasShortFlag(words, "clt") || words.some((w) => /^--(stdout|to-stdout|list|test)$/.test(w));
    if (!reads && args.some((a) => !a.startsWith("-"))) return `${name} replaces the files it is given`;
  }
  if (name === "tar") {
    const mode = args[0]?.startsWith("--") ? "" : (args[0] ?? "");
    const dir = args.findIndex((a) => a === "-C" || a === "--directory");
    if (/[cxruA]/.test(mode) && !(mode.includes("x") && dir !== -1 && TEMP_PATH.test(args[dir + 1] ?? ""))) {
      return "tar writes files outside an absolute temporary directory";
    }
  }
  if (name === "unzip") {
    const dir = args.indexOf("-d");
    if (!hasShortFlag(optionWords(args), "lptvZz") && !(dir !== -1 && TEMP_PATH.test(args[dir + 1] ?? ""))) {
      return "unzip writes files outside an absolute temporary directory";
    }
  }
  if (name === "curl") return curlReason(args);
  if (name === "wget") {
    const toStdout = args.some((a, k) => /^(-q?O-|--output-document=-|--spider)$/.test(a) || (/^-q?O$/.test(a) && args[k + 1] === "-"));
    if (!toStdout) return "wget writes files";
  }
  if (name === "find") {
    if (args.includes("-delete")) return "find -delete removes files";
    for (let k = 0; k < args.length; k++) {
      if (/^-f(print0?|printf|ls)$/.test(args[k]) && !writable(args[k + 1] ?? "")) return `find ${args[k]} writes a file`;
      if (/^-(exec|execdir|ok|okdir)$/.test(args[k])) {
        const end = args.findIndex((a, m) => m > k && (a === ";" || a === "+"));
        const reason = commandReason(args.slice(k + 1, end === -1 ? undefined : end));
        if (reason || end === -1) return reason;
        k = end;
      }
    }
  }
  if (name === "xargs") {
    let k = 0;
    while (k < args.length && args[k].startsWith("-")) k += XARGS_VALUES.includes(args[k]) ? 2 : 1;
    return k < args.length ? commandReason(args.slice(k)) : null;
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

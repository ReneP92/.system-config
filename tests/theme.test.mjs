import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  readlinkSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterEach, beforeEach, test } from "node:test";

const repo = resolve(import.meta.dirname, "..");
const script = join(repo, ".scripts/theme");
const themesDir = join(repo, "themes");
const themes = readdirSync(themesDir)
  .filter((file) => file.endsWith(".conf"))
  .map((file) => file.slice(0, -".conf".length))
  .sort();

const REQUIRED_KEYS = [
  "LABEL",
  "FG",
  "BG",
  "CURSOR_BG",
  "CURSOR_FG",
  "SELECTION_BG",
  "SELECTION_FG",
  ...Array.from({ length: 16 }, (_, i) => `ANSI_${i}`),
  "TMUX_BG",
  "TMUX_SURFACE",
  "TMUX_GUTTER",
  "TMUX_FG",
  "TMUX_FG_DARK",
  "TMUX_YELLOW",
  "TMUX_ORANGE",
  "TMUX_BLUE",
  "TMUX_GREEN",
  "FZF_BG",
  "FZF_COLORS",
];

function palette(name) {
  const values = {};
  for (const line of readFileSync(join(themesDir, `${name}.conf`), "utf8").split("\n")) {
    const match = line.match(/^THEME_(\w+)="([^"]*)"/);
    if (match) values[match[1]] = match[2];
  }
  return values;
}

let home;
let bin;

// Each test gets its own HOME, and a PATH whose uname reports Linux (so no
// wallpaper is set) and whose tmux has no server.
beforeEach(() => {
  home = mkdtempSync(join(tmpdir(), "theme-test-"));
  bin = join(home, "bin");
  mkdirSync(bin);
  for (const [name, body] of [
    ["uname", 'echo Linux'],
    ["tmux", "exit 1"],
  ]) {
    writeFileSync(join(bin, name), `#!/bin/sh\n${body}\n`);
    chmodSync(join(bin, name), 0o755);
  }
});

afterEach(() => {
  rmSync(home, { recursive: true, force: true });
});

function theme(...args) {
  const result = spawnSync(script, args, {
    encoding: "utf8",
    env: {
      HOME: home,
      PATH: `${bin}:/usr/bin:/bin:/opt/homebrew/bin`,
      LANG: "en_US.UTF-8",
      FZF_PREVIEW_COLUMNS: "60",
      FZF_PREVIEW_LINES: "30",
    },
  });
  return { status: result.status, stdout: result.stdout, stderr: result.stderr };
}

function state(file) {
  return readFileSync(join(home, ".config/theme", file), "utf8").trim();
}

test("every theme has a complete palette, a Claude Code theme and a wallpaper", () => {
  assert.ok(themes.length > 0);
  for (const name of themes) {
    const values = palette(name);
    for (const key of REQUIRED_KEYS) {
      assert.ok(values[key], `${name}: THEME_${key} is missing`);
      if (key !== "LABEL" && key !== "FZF_COLORS") {
        assert.match(values[key], /^#[0-9a-fA-F]{6}$/, `${name}: THEME_${key} is not a hex color`);
      }
    }
    assert.ok(existsSync(join(repo, "assets/claude-themes", `${name}.json`)), `${name}: Claude Code theme`);
    assert.ok(
      existsSync(join(repo, "assets/wallpapers", `${name}-dark-wallpaper-2560x1440.png`)),
      `${name}: wallpaper`,
    );
  }
});

test("help lists the commands and themes", () => {
  const { status, stdout } = theme("help");
  assert.equal(status, 0);
  assert.match(stdout, /theme set <name>/);
  assert.match(stdout, new RegExp(`themes: ${themes.join(" ")}`));
});

test("without state the current theme is the default, and plain `theme` outside a terminal prints it", () => {
  assert.equal(theme("current").stdout, "rose-pine (default)\n");
  assert.equal(theme().stdout, "rose-pine (default)\n");
});

test("list marks the current theme and --names prints plain names", () => {
  assert.equal(theme("list", "--names").stdout, `${themes.join("\n")}\n`);
  theme("set", "tokyonight");
  const lines = theme("list").stdout.trimEnd().split("\n");
  assert.equal(lines.length, themes.length);
  assert.deepEqual(
    lines.filter((line) => line.startsWith("*")),
    ["* tokyonight   Tokyo Night"],
  );
});

test("set writes the state, links the palette and installs the Claude Code theme", () => {
  mkdirSync(join(home, ".config/theme"), { recursive: true });
  writeFileSync(join(home, ".config/theme/tmux-current.conf"), "stale");

  const { status, stdout } = theme("set", "nightowl");
  assert.equal(status, 0, stdout);
  assert.equal(state("current"), "nightowl");
  assert.equal(state("background"), "transparent");
  assert.equal(readlinkSync(join(home, ".config/theme/palette.conf")), join(themesDir, "nightowl.conf"));
  assert.ok(!existsSync(join(home, ".config/theme/tmux-current.conf")), "stale tmux link removed");
  assert.equal(
    readFileSync(join(home, ".claude/themes/active.json"), "utf8"),
    readFileSync(join(repo, "assets/claude-themes/nightowl.json"), "utf8"),
  );
  assert.equal(theme("current").stdout, "nightowl\n");
});

test("set keeps the background unless a flag is given", () => {
  theme("set", "tokyonight", "--opaque");
  assert.equal(state("background"), "opaque");
  theme("set", "rose-pine");
  assert.equal(state("background"), "opaque");
  assert.equal(theme("current").stdout, "rose-pine (opaque)\n");
  theme("set", "rose-pine", "--translucent");
  assert.equal(state("background"), "transparent");
});

test("the legacy `theme <name> [opaque]` form still switches", () => {
  assert.equal(theme("tokyonight", "opaque").status, 0);
  assert.equal(theme("current").stdout, "tokyonight (opaque)\n");
  assert.equal(theme("nightowl").status, 0);
  assert.equal(theme("current").stdout, "nightowl (opaque)\n");
});

test("background prints, sets and toggles the background", () => {
  theme("set", "tokyonight");
  assert.equal(theme("background").stdout, "translucent\n");
  theme("background", "toggle");
  assert.equal(theme("background").stdout, "opaque\n");
  theme("background", "toggle");
  assert.equal(theme("background").stdout, "translucent\n");
  theme("background", "opaque");
  assert.equal(state("background"), "opaque");
  assert.equal(state("current"), "tokyonight");
});

test("unknown themes, commands and options fail without changing state", () => {
  for (const args of [["set", "solarized"], ["solarized"], ["set"], ["set", "tokyonight", "--bogus"], ["background", "bogus"], ["list", "--bogus"], ["preview"]]) {
    const { status, stderr } = theme(...args);
    assert.equal(status, 1, args.join(" "));
    assert.match(stderr, /^theme: /, args.join(" "));
  }
  assert.match(theme("solarized").stderr, new RegExp(`themes: ${themes.join(" ")}`));
  assert.ok(!existsSync(join(home, ".config/theme/current")));
});

test("preview renders every theme in its own colors, padded to the preview width", () => {
  for (const name of themes) {
    const { status, stdout } = theme("preview", name);
    assert.equal(status, 0, name);
    const values = palette(name);
    assert.ok(stdout.includes(values.LABEL), `${name}: label`);
    const [r, g, b] = [1, 3, 5].map((i) => parseInt(values.BG.slice(i, i + 2), 16));
    assert.ok(stdout.includes(`48;2;${r};${g};${b}m`), `${name}: painted on its background`);
    const textLines = stdout.split("\n").filter((line) => line.startsWith("\x1b[38;2"));
    assert.ok(textLines.length >= 20, `${name}: text lines`);
    for (const line of textLines) {
      const visible = line.replace(/\x1b\[[0-9;]*m/g, "");
      assert.equal([...visible].length, 60, `${name}: line width of ${JSON.stringify(visible)}`);
    }
  }
});

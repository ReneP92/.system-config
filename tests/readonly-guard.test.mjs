import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { blockedReason } from "../.claude/hooks/readonly-guard.mjs";

const allowed = [
  "git status --short",
  "git -C ../repo diff main...HEAD -- src/",
  "git --no-pager log --oneline -20 | head",
  "git log --grep='a > b' --format='%h %s'",
  "git branch -vv",
  "git branch --show-current",
  "git stash list",
  "git config --get remote.origin.url",
  "rg -n 'TODO' src | wc -l",
  "npm test 2>&1 | tail -50",
  "node --test tests/ 2>/dev/null",
  "npx vitest run src/foo.test.ts",
  "find . -name '*.ts' -exec grep -l useEffect {} +",
  "echo \"$(git rev-parse HEAD)\"",
  "gh pr view 21 --json title,body",
  "gh pr diff 21",
  "gh api repos/o/r/pulls/21/comments",
  "jq . package.json > /tmp/pkg.json",
  "FOO=1 make -n",
  "mkdir -p /tmp/review && cp src/cache.js /tmp/review/",
  "rm -rf /tmp/review",
  "node --test 2>&1 | tee /private/tmp/out.txt",
  "cat > /tmp/review/repro.mjs <<'EOF'\nconst f = (a) => a > 1;\nrm -rf src\nEOF\nnode /tmp/review/repro.mjs",
  "cat <<-EOF > /var/folders/xy/T/notes.txt\n\tgit push\n\tEOF",
  "node <<EOF\nconsole.log([1, 2].map((x) => x * 2));\nEOF",
];

const blocked = [
  ["git commit -m wip", /git commit/],
  ["git status && git push origin main", /git push/],
  ["git -C repo checkout -b x", /git checkout/],
  ["git stash", /git stash/],
  ["git branch -D old", /git branch/],
  ["git tag v1.0", /git tag/],
  ["git fetch origin", /git fetch/],
  ["rm -rf build", /rm modifies files outside/],
  ["ls; /bin/rm x", /rm modifies files outside/],
  ["rm -rf /tmp/../Users/me", /rm modifies files outside/],
  ["cp /tmp/patched.js src/cache.js", /cp modifies files outside/],
  ["mv src/cache.js /tmp/cache.js", /mv modifies files outside/],
  ["cd /tmp/review && cat > repro.mjs <<EOF\nx\nEOF", /redirection to repro.mjs/],
  ["cat <<EOF > src/index.ts\nexport {};\nEOF", /redirection to src\/index.ts/],
  ["bash <<EOF\nrm -rf src\nEOF", /nested shells/],
  ["cat <<EOF\nx\nEOF\ngit push", /git push/],
  ["sed -i '' 's/a/b/' file.ts", /in-place/],
  ["perl -pi -e 's/a/b/' file.ts", /in-place/],
  ["echo hi > src/index.ts", /redirection/],
  ["cat a >> notes.md", /redirection/],
  ["npm install lodash", /npm install/],
  ["brew upgrade", /brew upgrade/],
  ["bash -c 'rm -rf /'", /nested shells/],
  ["echo $(git reset --hard)", /git reset/],
  ["echo \"`git clean -fd`\"", /git clean/],
  ["find . -name '*.log' -delete", /find -delete/],
  ["find . -exec rm {} \\;", /rm modifies files outside/],
  ["git ls-files | xargs -n1 rm", /rm modifies files outside/],
  ["gh pr merge 21", /gh pr merge/],
  ["gh api -X POST repos/o/r/issues", /gh api writes/],
  ["gh api repos/o/r/issues -f title=x", /gh api writes/],
  ["env FOO=1 git add .", /git add/],
];

test("read-only inspection and test commands are allowed", () => {
  for (const command of allowed) assert.equal(blockedReason(command), null, command);
});

test("commands that change the repo, files or packages are blocked", () => {
  for (const [command, reason] of blocked) assert.match(blockedReason(command) ?? "", reason, command);
});

test("the hook blocks with exit 2 and explains why on stderr", () => {
  const hook = fileURLToPath(new URL("../.claude/hooks/readonly-guard.mjs", import.meta.url));
  const run = (command) => spawnSync("node", [hook], {
    input: JSON.stringify({ tool_name: "Bash", tool_input: { command } }),
    encoding: "utf8",
  });
  const denied = run("git push");
  assert.equal(denied.status, 2);
  assert.match(denied.stderr, /Blocked: git push is not read-only/);
  assert.equal(run("git diff").status, 0);
  assert.equal(spawnSync("node", [hook], { input: "not json" }).status, 0);
});

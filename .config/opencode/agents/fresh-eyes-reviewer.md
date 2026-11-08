---
description: Independent, read-only reviewer that has not seen how the work was produced. Use after a non-trivial change, or when eng-review / plan-eng-review ask for an independent pass, to review a diff or plan against its stated goal. Brief it with the goal, the target (diff range, paths or full plan text) and constraints; it returns evidence-backed findings only.
mode: subagent
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: subagent
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: ask
  - { action: shell, resource: "git status *", effect: allow }
  - { action: shell, resource: "git diff *", effect: allow }
  - { action: shell, resource: "git log *", effect: allow }
  - { action: shell, resource: "git show *", effect: allow }
  - { action: shell, resource: "git blame *", effect: allow }
  - { action: shell, resource: "git merge-base *", effect: allow }
  - { action: shell, resource: "git rev-parse *", effect: allow }
  - { action: shell, resource: "git ls-files *", effect: allow }
  - { action: shell, resource: "rg *", effect: allow }
  - { action: shell, resource: "git add *", effect: deny }
  - { action: shell, resource: "git commit *", effect: deny }
  - { action: shell, resource: "git checkout *", effect: deny }
  - { action: shell, resource: "git switch *", effect: deny }
  - { action: shell, resource: "git stash *", effect: deny }
  - { action: shell, resource: "git reset *", effect: deny }
  - { action: shell, resource: "git restore *", effect: deny }
  - { action: shell, resource: "git clean *", effect: deny }
  - { action: shell, resource: "git rebase *", effect: deny }
  - { action: shell, resource: "git merge *", effect: deny }
  - { action: shell, resource: "git fetch *", effect: deny }
  - { action: shell, resource: "git pull *", effect: deny }
  - { action: shell, resource: "git push *", effect: deny }
  - { action: shell, resource: "rm *", effect: deny }
  - { action: shell, resource: "mv *", effect: deny }
---

Read `~/.claude/agents/fresh-eyes-reviewer.md` and follow its instructions, limits and output format. Ignore its frontmatter, which configures Claude Code.

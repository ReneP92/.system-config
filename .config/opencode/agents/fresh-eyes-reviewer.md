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
  - { action: shell, resource: "git grep *", effect: allow }
  - { action: shell, resource: "git cat-file *", effect: allow }
  - { action: shell, resource: "git ls-tree *", effect: allow }
  - { action: shell, resource: "git rev-list *", effect: allow }
  - { action: shell, resource: "git shortlog *", effect: allow }
  - { action: shell, resource: "git describe *", effect: allow }
  - { action: shell, resource: "git name-rev *", effect: allow }
  - { action: shell, resource: "git show-ref *", effect: allow }
  - { action: shell, resource: "git for-each-ref *", effect: allow }
  - { action: shell, resource: "git branch", effect: allow }
  - { action: shell, resource: "git branch -a", effect: allow }
  - { action: shell, resource: "git branch -r", effect: allow }
  - { action: shell, resource: "git branch -v", effect: allow }
  - { action: shell, resource: "git branch -vv", effect: allow }
  - { action: shell, resource: "git branch -av", effect: allow }
  - { action: shell, resource: "git branch --show-current", effect: allow }
  - { action: shell, resource: "git branch --list *", effect: allow }
  - { action: shell, resource: "git branch --contains *", effect: allow }
  - { action: shell, resource: "git branch --merged *", effect: allow }
  - { action: shell, resource: "git branch --no-merged *", effect: allow }
  - { action: shell, resource: "git remote -v", effect: allow }
  - { action: shell, resource: "gh pr view *", effect: allow }
  - { action: shell, resource: "gh pr diff *", effect: allow }
  - { action: shell, resource: "gh pr checks *", effect: allow }
  - { action: shell, resource: "gh pr list *", effect: allow }
  - { action: shell, resource: "gh pr status *", effect: allow }
  - { action: shell, resource: "rg *", effect: allow }
  - { action: shell, resource: "grep *", effect: allow }
  - { action: shell, resource: "find *", effect: allow }
  - { action: shell, resource: "ls *", effect: allow }
  - { action: shell, resource: "pwd *", effect: allow }
  - { action: shell, resource: "cat *", effect: allow }
  - { action: shell, resource: "head *", effect: allow }
  - { action: shell, resource: "tail *", effect: allow }
  - { action: shell, resource: "nl *", effect: allow }
  - { action: shell, resource: "wc *", effect: allow }
  - { action: shell, resource: "cut *", effect: allow }
  - { action: shell, resource: "diff *", effect: allow }
  - { action: shell, resource: "stat *", effect: allow }
  - { action: shell, resource: "echo *", effect: allow }
  - { action: shell, resource: "printf *", effect: allow }
  - { action: shell, resource: "which *", effect: allow }
  # The last matching rule wins and a resource keeps its redirects, so any
  # redirect (even 2>&1) asks. Globs cannot tell a safe redirect from a
  # file write once the command prefix is a wildcard.
  - { action: shell, resource: "*>*", effect: ask }
  # Options of allowed commands that write files or run other programs.
  - { action: shell, resource: "git diff *--output*", effect: deny }
  - { action: shell, resource: "git log *--output*", effect: deny }
  - { action: shell, resource: "git show *--output*", effect: deny }
  - { action: shell, resource: "git grep *-O*", effect: deny }
  - { action: shell, resource: "git grep *--op*", effect: deny }
  - { action: shell, resource: "gh pr *--web*", effect: deny }
  - { action: shell, resource: "gh pr * -w*", effect: deny }
  - { action: shell, resource: "gh pr *--watch*", effect: deny }
  - { action: shell, resource: "rg *--pre*", effect: deny }
  - { action: shell, resource: "rg *--hostname-bin*", effect: deny }
  - { action: shell, resource: "find *-delete*", effect: deny }
  - { action: shell, resource: "find *-exec*", effect: deny }
  - { action: shell, resource: "find *-ok*", effect: deny }
  - { action: shell, resource: "find *-fprint*", effect: deny }
  - { action: shell, resource: "find *-fls*", effect: deny }
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

Do not add redirects such as `2>&1` or `2>/dev/null` to shell commands: the shell tool already returns stderr, and any redirect needs the user's approval.

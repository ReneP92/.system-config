# Feature map example

An example for a notes app with a web UI and a CLI, driven by a helper script at `.claude/skills/verify-notes/scripts/verify-notes`. Commands run from the repository root. Copy the shape, not the content.

## `features/README.md`

```markdown
# Notes verification map

This directory is the maintained source for verifying the user-facing behavior of Notes. Read this index before driving the app, then use the matching feature file as the recipe.

## Baseline preconditions

- Launch Notes with `.claude/skills/verify-notes/scripts/verify-notes launch`. It picks a free port, prints the URL, keeps all data under `$TMPDIR/notes-verify-<run-id>` by setting `NOTES_DATA_DIR` and `NOTES_CONFIG_DIR`, and records the process group for cleanup.
- The launch seeds notes titled `Quarterly plan` and `Grocery list`.
- Run `.claude/skills/verify-notes/scripts/verify-notes doctor` and require the run's URL, data and config directories, and the expected build revision.
- Evidence goes to `$TMPDIR/notes-verify-<run-id>/evidence/<feature-id>/` and survives cleanup.
- Never drive an instance this run did not start.

## Driving conventions

- Start every recipe from the baseline state unless its preconditions say otherwise.
- Prefer accessible roles and names over CSS selectors or DOM position.
- Treat every command as literal.
- Restore seeded data after a mutation. Never remove proof artifacts during cleanup.

## Proof

- Capture the user action and the resulting state, not only the final screen.
- UI proof is an accessibility snapshot plus a screenshot with the app identity visible.
- CLI proof is the command, stdout, stderr and exit code.
- Mutation proof includes a second, read-only view of the stored value.
- Record the feature ID and entry point with every artifact.
- Report an unreachable entry point with the attempted command and the unmet precondition. Never report a skipped entry point as verified through a different one.

## Feature file contract

Each feature file starts with an H1 title and one paragraph describing the user-visible behavior, then exactly four H2 sections in this order: `Sub-features` (short IDs, one line each), `How to get to it (user POV)` (every entry point), `Driving it with <harness>` (starts with `Preconditions:`, then labeled bullets pairing each user action with an exact command and the observable result) and `Gotchas` (traps that waste or invalidate a run). Keep implementation details out of the map.

## Features

- [Create a note](./create-note.md): browser and CLI creation, cancellation and persistence.
- [Search notes](./search.md): toolbar, keyboard and CLI search with matching, empty and cleared states.
```

## `features/create-note.md`

```markdown
# Create a note

A user saves a titled note from the browser or the CLI, can cancel an unfinished draft, and sees the saved note again from the note list.

## Sub-features

- `create-open` opens a blank editor from each browser entry point.
- `create-save` persists a title and body.
- `create-cancel` discards an unfinished browser draft.
- `create-cli` creates the same note from the terminal.

## How to get to it (user POV)

- Choose the `New note` button in the browser toolbar.
- Press `n` in the browser while focus is outside a text field.
- Run `notes create --title <title> --body <body>` in a terminal.

## Driving it with verify-notes

Preconditions:

- `.claude/skills/verify-notes/scripts/verify-notes doctor` passes.
- No note is titled `Release checklist`.

- **Open editor.** Run `.claude/skills/verify-notes/scripts/verify-notes browser click --role button --name "New note"`. A form named `Note editor` appears with focus in the `Title` textbox.
- **Save note.** Run `.claude/skills/verify-notes/scripts/verify-notes browser fill --role textbox --name "Title" --value "Release checklist"`, then `.claude/skills/verify-notes/scripts/verify-notes browser click --role button --name "Save note"`. A status named `Note saved` appears.
- **Confirm persistence.** Run `.claude/skills/verify-notes/scripts/verify-notes browser click --role link --name "All notes"`, then `.claude/skills/verify-notes/scripts/verify-notes browser click --role link --name "Release checklist"`. The editor shows the saved title.
- **Cancel draft.** Open a new note, fill the title `Discard me`, and run `.claude/skills/verify-notes/scripts/verify-notes browser click --role button --name "Cancel"`. The note list has no `Discard me` link.
- **CLI entry.** Run `.claude/skills/verify-notes/scripts/verify-notes cli -- notes create --title "CLI note" --body "From terminal" --format json`. Exit code `0`, and stdout contains the new note ID.
- **Proof.** From `All notes`, run `.claude/skills/verify-notes/scripts/verify-notes capture create-note/list`. The snapshot and screenshot show `Release checklist` and `CLI note`.

## Gotchas

- Pressing `n` while a text field has focus types the letter instead of opening an editor.
- Titles are trimmed on save. Assert the rendered title, not the typed value.
- A save status alone is not proof. Reopen the note from the list.
- Cleanup removes `Release checklist` and `CLI note` but keeps their proof artifacts.
```

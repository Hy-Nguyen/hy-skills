---
name: save-progress
description: Save progress on a learning project as a git commit whose message explains what was worked on and, when a course/assignment file exists, which assignment that was and what's next. Use when the user invokes /save-progress, or says "save my progress", "checkpoint this", or similar while working through a learning/practice project.
---

# Save Progress

The user invoked `/save-progress [notes]`. Commit the current work with a message that works as a study log: someone reading `git log` later should see what was done, what was learned, and what to pick up next. Anything in the arguments is context from the user (what they did, what clicked, what's still confusing) — fold it into the message.

This commits locally. Don't push unless the user asks.

## 1. Look at the state

Run these in parallel:

- `git status` (never `-uall`)
- `git diff` and `git diff --staged`
- `git log -10 --format='%h %s%n%b---'` — commit style, plus the `Next:` line from the last progress commit
- Look for a course file (step 2)

Not a git repo → ask whether to `git init` first. Nothing to commit → say so and stop. Mid-merge/rebase or conflicts → stop and tell the user.

## 2. Find the course module (optional)

Look in the repo root, then `docs/`, for the first match:

- `COURSE.md`, `ASSIGNMENTS.md`, `CURRICULUM.md`, `SYLLABUS.md`, `ROADMAP.md`, `PLAN.md`, `TODO.md`
- a `course/`, `assignments/`, `lessons/`, or `exercises/` folder (numbered files or a README index)

A course file is anything that lists the tasks in order — a markdown checklist, numbered headings, numbered files. See [references/course-template.md](references/course-template.md) for the suggested format.

**Found one:**

1. Match the diff to an assignment. Prefer the first unchecked item; confirm by comparing what it asks for with what changed. If the diff spans several assignments, list each.
2. Decide its status: **done** (what the assignment asks for is implemented — and tests pass, if the project has them and they're quick to run) or **in progress**. When unsure, call it in progress and say why in the report.
3. If done, check it off in the course file (`- [ ]` → `- [x]`) and include that edit in the commit. Don't otherwise rewrite the course file.
4. Next task = the next unchecked item (or the remainder of the current one if in progress).

**None found:** skip all of this. Use the previous progress commit's `Next:` line as a hint for what the user was aiming at, if there is one. Only write a `Next:` section if the user's notes or the code itself (TODO comments, half-finished function, failing test) make the next step obvious — don't invent one.

## 3. Stage

- Stage files by name. Never `git add -A` / `git add .`.
- Leave out secrets and junk: `.env*`, keys, tokens, `node_modules/`, build output, large binaries, `.DS_Store`. Mention anything you skipped. If there's no `.gitignore` and junk is showing up, offer to add one.
- Half-finished or broken code is fine to commit — that's the point of saving progress. Just say so in the message.

## 4. Write the message

Subject: Conventional Commits unless `git log` shows another style. Scope = the assignment id when there is one.

```
feat(02-linked-list): implement insert and delete

Assignment: 02 — Linked list (done)

Worked on:
- Singly linked list with insert-at-index and delete-by-value
- Tests for empty list and out-of-range index

Learned:
- Keeping a dummy head node removes the special case for index 0

Next: 03 — Stack using the linked list
```

- **Subject** (≤ 72 chars, imperative): the concrete thing that changed. For in-progress work, `wip(scope): …` is fine.
- **Assignment** — only with a course file. Number, title, and `(done)` / `(in progress)`.
- **Worked on** — 1–4 bullets of what was built or changed, in terms of the problem, not a file list.
- **Learned / Stuck on** — only if the user's notes or the session make it clear. Never make up insights.
- **Next** — from the course file, or omitted per step 2.
- End with the commit attribution lines the harness/system instructions specify — no others.

Commit with a heredoc (`git commit -F - <<'EOF' … EOF`), not chained `-m`. Never `--no-verify`; if a hook fails, fix the cause and make a fresh commit.

## 5. Report

Two or three lines: the commit subject and short hash, the assignment status, and what's next. Mention any files you left out.

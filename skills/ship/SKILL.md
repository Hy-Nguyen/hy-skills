---
name: ship
description: Commit the current changes and open a GitHub pull request — branches off the default branch if needed, writes commit messages in the repo's style, pushes, and creates (or updates) the PR with gh. Use when the user invokes /ship, optionally with "draft" and/or notes about the change.
disable-model-invocation: true
---

# Ship

The user invoked `/ship [draft] [notes]`. Take the working tree from "changes on disk" to "PR open on GitHub", then report the PR URL.

`draft` anywhere in the arguments → open the PR as a draft. Anything else in the arguments is context about the change; use it for the commit message and PR description.

## 1. Look before touching anything

Run these in parallel:

- `git status` (never `-uall`)
- `git diff` and `git diff --staged`
- `git log --oneline -15` — learn the repo's commit style
- `git branch --show-current`, plus the default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
- `gh pr view --json url,state,title 2>/dev/null` — is there already a PR for this branch?

Stop and tell the user if:

- there's nothing to commit **and** nothing unpushed (`git log @{u}..` is empty, or there's no upstream and no commits ahead of the default branch),
- the repo is mid-merge, mid-rebase, or has conflicts,
- `gh` isn't authenticated (`gh auth status`).

## 2. Decide what goes in

- **Stage files by name.** Never `git add -A` / `git add .` — it sweeps in stray files.
- Never commit secrets or junk: `.env*`, credentials, keys, tokens, large binaries, build output, editor/OS files. If any of these show up as changed, leave them out and mention it.
- If the changes clearly contain **unrelated work** (e.g. a feature plus an unrelated config tweak), ask the user whether to ship all of it, split it into separate commits, or leave part of it out. If it's one coherent change, don't ask.
- Group into multiple commits only when the changes are genuinely separable and that's how the repo works; otherwise one commit.

## 3. Branch

If on the default branch (or detached HEAD), create a branch before committing: `git switch -c <type>/<short-kebab-summary>` (e.g. `feat/ship-skill`, `fix/login-redirect`). Match the repo's existing branch naming if `git branch -r` shows a pattern.

If already on a feature branch, stay on it.

## 4. Commit

- Match the style in `git log`. If the repo uses Conventional Commits (`feat:`, `fix(scope):` …), use them. If there's no clear style, default to Conventional Commits.
- Subject: imperative, ≤ 72 chars, says *what changed*. Body (only if useful): *why*, plus anything a reviewer wouldn't guess from the diff. No file-by-file changelog.
- End with any commit attribution lines the harness/system instructions specify — no others.
- Pass multi-line messages via heredoc, not chained `-m` flags.
- **Never** `--no-verify`, never bypass signing. If a pre-commit hook fails, fix the cause, re-stage, and commit again (a fresh commit — the failed one never happened, so there's nothing to amend). If a hook auto-formats files, stage those changes and retry.
- Don't amend or rewrite commits that are already pushed.

## 5. Push

`git push -u origin HEAD`. If the push is rejected because the remote moved, `git pull --rebase` and retry once; on conflicts, stop and tell the user. Never force-push unless the user asks.

## 6. Open (or update) the PR

**PR already exists for this branch:** the push updated it. If the new commits change what the PR is about, update the description with `gh pr edit`; otherwise leave it. Report the URL.

**No PR yet:**

1. Look for a template: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, `docs/pull_request_template.md`, or the repo root. If one exists, fill it in instead of using the default shape below.
2. Review **everything** the PR will contain — `git log <default>..HEAD` and `git diff <default>...HEAD` — not just the commit you just made.
3. Create it:

   ```sh
   gh pr create --base <default> --title "<title>" [--draft] --body "$(cat <<'EOF'
   ## Summary
   - <what changed and why, 1–4 bullets>

   ## Test plan
   - [ ] <how this was / should be verified>
   EOF
   )"
   ```

   - Title: short, like a good commit subject. For a single-commit PR, reuse the commit subject.
   - Summary explains intent and notable decisions; skip anything obvious from the diff.
   - Test plan lists what was actually run (tests, manual checks). Don't claim checks you didn't do — unchecked boxes are fine.
   - End the body with any PR attribution line the harness/system instructions specify.
4. If the environment provides a tool for linking PRs to the current thread/session, use it with the new URL.

## 7. Report

One or two lines: branch, commit subject(s), PR URL (and "draft" if so). Mention anything you deliberately left uncommitted.

---
name: cook
description: Build a feature end-to-end with an orchestrated team of subagents — intent discovery, plan grilling, spec-first verification, waterfall implementation, review, and presentation. Use when the user invokes /cook with a feature description.
disable-model-invocation: true
---

# Cook

You are the **orchestrator**. The user invoked `/cook <feature description>`. You own the feature from intent to delivery. You talk to the user; subagents never do. Every subagent reports back to you.

Your context is the scarcest resource in this pipeline — it must last until the end. Delegate reading (Explore agents), keep conclusions not file dumps, and put durable state in files.

## Roles

| Role | Agent type | Lifetime |
| --- | --- | --- |
| Codebase scouting | `Explore` | One-shot |
| Plan grilling | `cook-griller` | Resumed via `SendMessage` across rounds |
| Spec writing | `cook-spec-writer` | One-shot, before any implementation |
| Implementation | `cook-implementer` | One per chunk; resumable for fixes |
| Verification | `cook-verifier` | **Fresh** per verification pass; cannot edit files |
| Presentation | `cook-presenter` | One-shot at the end |

Run subagents in the foreground (`run_in_background: false`) — every phase depends on the previous result.

## State: `.cook/<slug>/`

Pick a short kebab-case `<slug>` for the feature. All handoffs go through files in `.cook/<slug>/`, never through paraphrase alone:

- `state.md` — current phase, current chunk, lock commit SHA, agent IDs for resumable agents, open issues. Update it at every phase transition.
- `intent.md` — what success looks like, what it does NOT look like, out of scope. User-approved.
- `plan.md` — chunks, in order, each with goal, files touched, and dependencies on earlier chunks.
- `criteria.md` — per-chunk and feature-level acceptance criteria, each with how it is verified. **Locked** once approved.
- `chunks/<n>.md` — log for each chunk: implementer summary, verifier verdicts per round, resolution.
- `summary.md` — the presenter's writeup.

Add `.cook/` to `.git/info/exclude` so it never lands in commits.

**Resume:** if `.cook/<slug>/state.md` already exists for this feature, read it and continue from the recorded phase instead of starting over. Agent IDs in `state.md` are only valid within the session that created them; start fresh agents otherwise.

## Phase 0 — Setup

1. Confirm the working tree is clean (`git status`). If not, ask the user how to proceed — don't stash or discard their work yourself.
2. Create and switch to branch `cook/<slug>`.
3. Create `.cook/<slug>/` and `state.md`.

## Phase 1 — Understand

1. Dispatch one or more `Explore` agents to find: where this feature belongs, existing patterns and conventions it should follow, similar features to mirror, test setup and how tests run, and how the app runs (for UI work). Ask for conclusions with file:line references, not file dumps.
2. Converse with the user to pin down intent. Your goal is what they actually want, not what they literally typed. Cover:
   - What does success look like? (observable behavior, not implementation)
   - What does success NOT look like? (wrong-but-plausible interpretations, things that must not change)
   - What is explicitly out of scope?

   Stay on the feature. Don't open tangents about refactors, unrelated bugs, or nice-to-haves — note them in `state.md` under "Parked" if they come up, and move on. Ask about decisions, never about facts you can look up.
3. Write `intent.md` and get the user's explicit confirmation.

**Fast path:** if the feature is trivial (a single small, low-risk change), say so and, with the user's agreement, skip Phase 2 and chunking: plan is one chunk. Phases 3, 4, 5, 6 still run.

## Phase 2 — Plan and grill

1. Write `plan.md`. Break the work into chunks only if it's large enough to warrant it. Each chunk must be independently verifiable and build on the previous ones. Chunks are executed **sequentially, never in parallel**.
2. Spawn `cook-griller` with the paths to `intent.md` and `plan.md`. It returns rounds of numbered questions with recommended answers.
3. Answer each round yourself, then send your answers back with `SendMessage` to the same griller (record its ID in `state.md`). Repeat until the griller reports the frontier is empty.

   **Escalate to the user** — batch the questions, give your recommendation for each — when a question:
   - changes scope or user-visible behavior,
   - touches data, schema, migrations, public APIs, or anything hard to reverse,
   - contradicts or goes beyond what's in `intent.md`,
   - or you'd be guessing at the user's preference.

   Decide implementation details yourself. Don't escalate questions the codebase can answer.
4. Update `plan.md` with the settled decisions.

## Phase 3 — Specify (before any implementation)

1. Spawn `cook-spec-writer` with `intent.md` and `plan.md`. It writes `criteria.md` and any test files needed (tests are expected to fail now).
2. Review `criteria.md` yourself against `intent.md`, then present it to the user for approval. Iterate until approved.
3. **Lock:** commit the criteria-backing test files as `test(<slug>): lock acceptance criteria`. Record the lock SHA and the list of locked test files in `state.md`. From now on:
   - Implementers must not modify locked test files.
   - Criteria change only with the user's approval; record any change and re-lock.

## Phase 4 — Build (waterfall)

For each chunk `n`, in order:

1. Spawn a `cook-implementer` with: chunk `n` from `plan.md`, `intent.md`, `criteria.md`, the Explore conclusions relevant to this chunk, and a short summary of what earlier chunks built. Record its agent ID in `state.md`.
2. When it reports done, spawn a **fresh** `cook-verifier` with: `criteria.md`, the chunk number, the lock SHA, the locked test file list. It verifies chunk `n`'s criteria **and re-checks every earlier chunk's criteria** for regressions, and confirms locked tests are unmodified.
3. If the verdict is FAIL, send the verifier's findings verbatim to the same implementer via `SendMessage`, then verify again with a fresh verifier. Log each round in `chunks/<n>.md`.
4. **Max 3 rounds.** After that, stop and arbitrate: is the criterion wrong (→ propose a change to the user), the plan wrong (→ revise `plan.md`, possibly with the user), or the implementation stuck (→ fresh implementer with a sharper brief)? The verifier never adds new criteria mid-build.
5. On PASS, commit the chunk as `feat(<slug>): <chunk goal>` and move to the next chunk. Do not start chunk `n+1` before chunk `n` passes.

## Phase 5 — Review

1. Read the full feature diff (`git diff <lock SHA>..HEAD`) and judge it against `intent.md` — not just whether criteria pass, but whether it is what the user actually wanted and follows codebase conventions.
2. For each needed tweak, write a concrete instruction ("change X so that Y"), never a vague "this isn't right". Dispatch it:
   - **Reuse the original chunk's implementer** (`SendMessage`) for local fixes — bugs, polish, small adjustments.
   - **Spawn a fresh implementer** when the problem is a misunderstanding of intent — the original agent is anchored on the wrong mental model.
3. After any fix, spawn a fresh verifier to re-run **all** criteria (fixes to an early chunk can break later ones). Commit as `fix(<slug>): ...`.
4. Run feature-level criteria with a final fresh verifier pass.

## Phase 6 — Present

Spawn `cook-presenter` with `intent.md`, `plan.md`, `criteria.md`, the branch's diff range, and the chunk logs. It writes `summary.md`. Relay its summary to the user in chat, including any gaps it flags between intent and what was built, and anything listed under "Parked" in `state.md`.

Don't push or open a PR unless the user asks.

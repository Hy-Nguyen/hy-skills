# hy-skills

My personal collection of agent skills (and the subagents some of them depend on).

## Layout

```
skills/<name>/SKILL.md   # one folder per skill; extra files (references, scripts) go alongside
agents/<name>.md         # Claude Code subagents used by skills (e.g. cook-* for /cook)
scripts/sync.sh          # symlinks skills + agents into each agent's config dir
scripts/setup.sh         # one-time setup: enables git hooks, runs sync
.githooks/               # re-run sync after pull / checkout / rebase
```

## Skills

| Skill | What it does | Needs |
| --- | --- | --- |
| [`cook`](skills/cook/SKILL.md) | `/cook <feature>` — orchestrated build: intent → grill → spec → waterfall implement → review → present | `agents/cook-*.md` |
| [`ship`](skills/ship/SKILL.md) | `/ship [draft] [notes]` — commit current changes (branching off the default branch if needed), push, and open or update a PR | `gh` |
| [`save-progress`](skills/save-progress/SKILL.md) | `/save-progress [notes]` — commit learning-project work with a study-log message: what was done, which assignment (from `COURSE.md` if present), and what's next | — |

## How syncing works

`scripts/sync.sh` symlinks:

| From | To | Read by |
| --- | --- | --- |
| `skills/<name>/` | `~/.agents/skills/<name>` | Codex, Cursor, other agents following the `~/.agents` convention |
| `skills/<name>/` | `~/.claude/skills/<name>` | Claude Code |
| `agents/<name>.md` | `~/.claude/agents/<name>.md` | Claude Code subagents |

Because they're symlinks, editing a skill in this repo takes effect immediately everywhere — no re-sync needed. Re-sync is only needed when a skill is **added or removed**, and the git hooks do that automatically after `git pull`, `checkout`, or `rebase`.

Anything already in the way (a real file/folder with the same name) is moved to `~/.hy-skills-backup/<timestamp>/`. Symlinks pointing at skills deleted from this repo are pruned. Skills installed by other means (e.g. `npx skills add`) are left untouched.

## Setup on a new machine

```sh
git clone https://github.com/Hy-Nguyen/hy-skills.git ~/Code/hy-skills
~/Code/hy-skills/scripts/setup.sh
```

After that, `git pull` keeps everything in sync. Preview changes with `scripts/sync.sh --dry-run`.

## Adding a skill

1. Create `skills/<name>/SKILL.md` (see [CLAUDE.md](CLAUDE.md) for conventions).
2. If it needs subagents, add them to `agents/`.
3. Run `scripts/sync.sh`, add a row to the table above, commit.

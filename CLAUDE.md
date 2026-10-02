# hy-skills

A repo of agent skills, symlinked into `~/.agents/skills`, `~/.claude/skills`, and `~/.claude/agents` by `scripts/sync.sh`. Edits here are live for every agent on this machine immediately.

## Conventions

- One skill per folder: `skills/<kebab-name>/SKILL.md`. The folder name must equal the `name:` in frontmatter.
- Frontmatter: `name` and `description` are required. The description is what agents use to decide when to trigger — say what it does **and** when to use it.
- Set `disable-model-invocation: true` for skills that should only run when the user explicitly invokes them (e.g. `/cook`).
- Keep `SKILL.md` focused; put long reference material in sibling files (`references/*.md`) and link to them so they load on demand.
- Subagents a skill depends on live in `agents/<name>.md`, prefixed with the skill name (`cook-verifier.md`). Note the dependency in the README table.
- After adding or removing a skill/agent, run `scripts/sync.sh` and update the Skills table in `README.md`.

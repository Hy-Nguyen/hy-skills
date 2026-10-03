# Course file template

Drop a `COURSE.md` in the root of a learning project so `/save-progress` knows which assignment you're on and what comes next. The only hard requirement is an ordered list of tasks with checkboxes; everything else is optional.

```markdown
# Data Structures from Scratch

Goal: implement core data structures in TypeScript with tests.

## Assignments

- [x] 01 — Dynamic array: push, pop, get, resize
- [ ] 02 — Linked list: insert at index, delete by value, reverse
- [ ] 03 — Stack using the linked list
- [ ] 04 — Queue with two stacks
- [ ] 05 — Hash map with chaining

## Notes

- Every assignment needs tests in `tests/<nn>-*.test.ts`.
```

Tips:

- Give each assignment a short id (`01`, `02` …). It becomes the commit scope: `feat(02): …`.
- Put the acceptance criteria on the line or as nested bullets — that's what decides "done" vs "in progress".
- For longer courses, use a `course/` folder with one file per assignment (`course/02-linked-list.md`) and keep the checklist in `course/README.md`.

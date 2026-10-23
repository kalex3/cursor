# Proposals

Writable inbox mounted at `~/proposals` in the container. The agent writes **complete** files here to suggest
new or changed user-level rules and subagents:

- `proposals/rules/<name>.mdc`
- `proposals/agents/<name>.md`

Using the same file name as an existing rule/agent proposes a change to it. Nothing here takes effect until you
review it (`diff -ru rules proposals/rules`) and copy it into `rules/` or `agents/` yourself.

Everything except this file is git-ignored.

---
name: ask-questions-if-underspecified
description: Asks a few clarifying questions before implementing when two readings would produce different code, or a destructive step has no named target or rollback. Use when the objective, scope, or safety of a change is unclear. Skip when the request, the code, or an existing rule already settles it.
---

# Ask questions if underspecified

Adapted from [trailofbits/skills](https://github.com/trailofbits/skills/blob/cfe5d7b1619e47fb5b38b7e2561dad7e5f1e89af/plugins/ask-questions-if-underspecified/skills/ask-questions-if-underspecified/SKILL.md).

A settled reading is not underspecified. If the request, the code, or an existing rule already settles it, state the assumption in a sentence and proceed. A quick read of the repo counts as settled. Do not ask about this environment's OS, shell, test runner, or style when those rules already answer it.

## When it is underspecified

Two readings would produce different code, or a destructive or irreversible step (migration, rollout, delete, scan) has no named target or rollback.

Ask 1–5 questions that each eliminate a branch of work. Then stop. Do not edit files, run commands, or write a plan that depends on the unknown. A read of the repo structure or config is fine when it does not choose a direction.

Use the structured question tool when it is available, with the recommended option first. Otherwise use a numbered list with lettered choices:

- Bold the recommended choice.
- Include "Not sure — use default" when a default exists.
- Accept `defaults` as every recommended choice.
- Accept a compact reply such as `1a 2c`, then restate those choices in plain language.

```text
1) Scope?
a) Minimal change (default)
b) Refactor while touching the area
c) Not sure — use default

Reply with: defaults (or 1a)
```

When the answers arrive, restate the requirement in one to three sentences, including what success looks like, and start.

When the user says to proceed without answers, state the assumptions and start.

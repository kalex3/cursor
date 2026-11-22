---
name: systematic-debugging
description: Finds the root cause of a bug, test failure, or unexpected behavior before changing code. Reproduce it, state one hypothesis, then apply a single fix. Use when debugging, when a test fails, when behavior is wrong, when a build breaks, or when a fix has already failed.
---

# Systematic debugging

Adapted from [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md). A fix lands after the cause is known. Karpathy still applies: one surgical change, then a check.

## 1. Read the failure

Read the full error, stack, and the lines it names. Note the file, line, and code.

## 2. Reproduce

Trigger it the same way every time. Record the exact command or steps, and what you expected.

When the project has tests, add one failing test that shows the bug, then run it. Use the runner the repo already uses (`uv run pytest` in a uv project, otherwise `pytest`, `go test -race`, `cargo test`, or the repo's Vitest or Jest script).

When the project has no tests, the reproduction is the smallest command that fails. Leave the test setup alone.

When it used to work, `git bisect` from a known-good commit. When the failure is deep, trace the bad value to the call that produced it and fix that source.

This image has no browser. For a UI bug, name the check you could not run.

If it does not reproduce, name what you ran and stop. Two different causes that imply different edits are a stop as well. If the error and the code already settle the cause, say that in a sentence and continue.

## 3. One hypothesis

State it as "X is the cause because Y". Compare with the nearest working code in the repo and list the differences that matter.

Test with the smallest change that can confirm or reject that one claim. A failed test of the hypothesis means a new hypothesis, not another fix stacked on the old one.

## 4. One fix

Change the cause. Remove any temporary logging you added. Leave unrelated code, comments, and formatting alone.

Confirm the reproduction now passes, and that the existing tests for the touched code still pass. Say what you ran.

After three failed fixes, stop. Name the coupling or design problem the attempts exposed. Wait before another edit.

## Evidence

| What you see | Where to look |
| --- | --- |
| It worked before | `git bisect`, `git log`, `git diff` |
| Wrong value | Each transformation from the source of the value |
| Intermittent | Race, clock, unseeded randomness, uninitialized state |
| Only in prod or CI | Env, versions, and data that differ from this container |
| Useless message | The site that throws it |

Do not print secrets, tokens, or customer load and price series while gathering evidence.

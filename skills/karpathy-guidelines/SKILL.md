---
name: karpathy-guidelines
description: Applies Andrej Karpathy's coding-behavior guidelines when writing, editing, reviewing, or refactoring code. State assumptions, keep the change minimal and surgical, and loop until a check passes. Use when implementing, fixing, reviewing, or restructuring code, or when the user mentions Karpathy, overcomplication, drive-by refactors, or verifiable success criteria.
---

# Karpathy guidelines

Derived from [Andrej Karpathy's notes](https://x.com/karpathy/status/2015883857489522876) via [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) (MIT). Adapted for this container.

Bias toward caution over speed. For a trivial change, just make it.

## Think before coding

State assumptions in a sentence. If the request, the code, or an existing rule already settles the question, proceed with that assumption. Ask only when two readings would produce different code, and follow `ask-questions-if-underspecified` for that case. If a simpler approach exists, say so and use it. If something is genuinely unclear, name it and stop.

## Simplicity first

Write the minimum code that solves the problem. No features, abstractions, configurability, or error handling beyond what was asked. If the change is much longer than the problem needs, rewrite it shorter.

## Surgical changes

Touch only what the request requires. Match the existing style. Leave unrelated code, comments, and formatting alone. Mention unrelated dead code; do not delete it. Remove imports, variables, and functions that this change made unused.

Every changed line traces to the request.

## Goal-driven execution

Define a check and loop until it passes.

- A bug fix starts from a failing test when the project has tests.
- A web UI change is verified in the browser when one is available. This image has none, so say what you could not verify.
- A refactor keeps existing tests passing.
- For multi-step work, use a short plan of step, then verify.

Do not commit, stage, or push unless asked. Do not open a pull request unless asked.

## In this container

Commands you run use bash. Commands you give the user to paste must also work in fish: no `export`, `[[ ]]`, `${var:-x}`, or heredocs; one simple command per line.

Read the matching always-on rule instead of restating it: `container`, `leave-commits`, `no-ai-attribution`, `anti-sycophancy`, `anti-overengineering`. File-scoped rules (`python-testing`, `shell`, `security`, and the language rules) apply when those files are in play.

These guidelines are working when diffs stay small, the code stays simple, and questions come before the wrong implementation.

## Examples

See [examples.md](examples.md).

# Examples

Show the assumption, then the smallest change that satisfies it. Stop only when two readings would produce different code.

## Settled reading

Request: "Add a function to calculate a percent discount."

Assumption: one function, percent in the range 0–100, return the discount amount. The codebase has no discount types.

```python
def calculate_discount(amount: float, percent: float) -> float:
    return amount * (percent / 100)
```

A strategy hierarchy, config object, or cache waits until a second discount kind actually exists.

## Two readings, stop

Request: "Add a feature to export user data."

File download, a JSON API, and a background job are different code. Name that and stop. Do not pick a format, a field list, or "all users" and build it.

## Surgical bug fix

Request: "Empty emails crash the validator."

The project has tests. Add a failing test for an empty email, then change only the lines that make that test pass. Leave username checks, comments, quotes, and type hints as they are. If an unused import is left behind by that edit, remove it.

## Multi-step plan

Request: "Add rate limiting to the API."

```
1. In-memory limit on one endpoint → verify: a test shows 429 after the cap
2. Middleware for the other endpoints → verify: existing endpoint tests still pass
```

Do step 1. Step 2 stays unwritten until step 1 passes. Redis, per-route config, and metrics are separate requests.

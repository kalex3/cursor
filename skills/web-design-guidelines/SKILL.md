---
name: web-design-guidelines
description: Reviews UI code against the Vercel Web Interface Guidelines and reports file:line findings. Use only when the user asks for a UI review, an accessibility check, a design audit, a UX review, or a check against interface guidelines.
---

# Web interface guidelines

Review UI source against the current [Vercel Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines). This is a review. Leave the code unchanged unless the user also asks for the fixes.

## Steps

1. Fetch the rules:

   `https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md`

2. Read the files the user named. When they did not name files, read the UI files in the current change. When those two readings still disagree, name the candidate paths and stop.

3. Check each file against every rule in the fetched document.

4. Report in the fetched format. Group by file, use `file:line`, and stay terse. A clean file is one `✓ pass` line. Skip a finding you cannot point at.

A failed fetch stops the review. Say that the guidelines URL did not load.

This skill reads the source. The image has no browser, so behavior, console, and network checks stay unverified unless the user runs them.

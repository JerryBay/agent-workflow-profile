---
name: minimal-scope-repo-change
description: Use when modifying an existing repo, fixing a bug, adding a narrow feature, preserving user changes, choosing where code should live, or verifying a change with project-specific commands.
---

# Minimal-Scope Repo Change

## Core Rule

Make the smallest repo-appropriate change that satisfies the request, then verify it with the project's real path.

## Workflow

1. Read the nearby code and ownership boundaries before editing.
2. Identify the module, node, command, component, or subsystem that already owns similar behavior.
3. Keep changes local to that ownership area unless the evidence shows a shared contract must change.
4. Prefer existing helpers, conventions, config formats, and test style.
5. Avoid unrelated refactors, metadata churn, broad rewrites, and speculative abstractions.
6. Protect user work: do not revert unrelated dirty files or edits you did not make.
7. Verify with the narrowest meaningful command: focused test, target build, runtime repro, or UI path.
8. Report changed files, verification command, and any residual risk.

## Placement Heuristics

| Question | Default |
| --- | --- |
| Where should this behavior live? | Near the existing owner of the same state, lifecycle, render path, or persistence hook |
| Should shared code change? | Only if multiple real call sites need the same contract |
| Should config be added? | Use existing config when present; otherwise prefer a small user-tunable default over hardcoded assumptions |
| Should values be normalized or clamped? | Preserve original semantics unless the user requested normalization or evidence proves it is required |

## Verification

Do not claim the change is complete from inspection alone. If the real full build is blocked by existing workspace issues, run the narrow viable command and state the limitation.

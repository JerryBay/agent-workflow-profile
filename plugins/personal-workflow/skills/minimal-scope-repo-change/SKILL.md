---
name: minimal-scope-repo-change
description: Use when modifying an existing repo, fixing a bug, adding a narrow feature, preserving user changes, choosing where code should live, or verifying a change with project-specific commands.
---

# Minimal-Scope Repo Change

## Core Rule

Make the smallest design-correct, repo-appropriate change that satisfies the request, then verify it with the project's real path. Smallest does not mean the fewest-line patch.

## Workflow

1. Establish the task mode, requirement boundary, and relevant acceptance level before editing.
2. Read the nearby code and ownership boundaries.
3. Identify the module, node, command, component, or subsystem that already owns similar behavior.
4. Check whether the change affects module boundaries, data ownership or shape, or a plausible hot path. Preserve high cohesion and low coupling; justify the smallest structural widening when a local patch would put behavior under the wrong owner.
5. Prefer existing helpers, conventions, config formats, and test style.
6. Avoid unrelated refactors, metadata churn, broad rewrites, and speculative abstractions.
7. Protect user work: do not revert unrelated dirty files or edits you did not make.
8. Verify with the narrowest meaningful command that reaches the required acceptance level.
9. Report changed files, verification evidence, unverified behavior, and residual risk.

## Placement Heuristics

| Question | Default |
| --- | --- |
| Where should this behavior live? | Near the existing owner of the same state, lifecycle, render path, or persistence hook |
| Should shared code change? | Only if multiple real call sites need the same contract |
| Should config be added? | Use existing config when present; otherwise prefer a small user-tunable default over hardcoded assumptions |
| Should values be normalized or clamped? | Preserve original semantics unless the user requested normalization or evidence proves it is required |
| Should the data structure change? | Only when dominant operations, scale, lifetime, ownership, ordering, or concurrency requirements justify it |
| Should performance be optimized now? | Only when constraints or evidence indicate material risk; measure with representative inputs when practical |

## Verification Ladder

Choose the required levels before implementation. Run only the levels relevant to the request, but do not imply that a lower level proves a higher one.

| Level | Evidence |
| --- | --- |
| Inspection | Current diff, call path, ownership, or configuration is understood |
| Build | The affected target compiles or type-checks |
| Focused tests | The smallest relevant automated tests pass |
| Runtime | The real executable, process, logs, or reproduction path confirms behavior |
| Visible result | UI state, rendering, output, or user-visible behavior matches the acceptance criteria |
| Persistence | Reopen, restart, replay, or a fresh shell/session preserves the intended state |

## Completion Reporting

Separate implemented, verified, and unverified work. If the full acceptance path is blocked by existing workspace issues, run the narrow viable command and state the exact limitation.

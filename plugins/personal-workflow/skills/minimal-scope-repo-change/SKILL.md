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
5. Prefer existing helpers, conventions, config formats, and test style. If the chosen path starts requiring auxiliary assets, compensating conversions, or new user restrictions, reassess it against the existing representation and workflow before extending the patch. Explain whether these costs are inherent or avoidable; confirm newly exposed material impacts outside existing authorization. Do not encode a workaround's limitations as export or input validation requirements without this review. Keep equivalent local fixes on the fast path.
6. Avoid unrelated refactors, metadata churn, broad rewrites, and speculative abstractions. When successive fixes keep adding special-case branches, state variables, or fallbacks, revisit the problem model and existing invariants before adding another patch.
7. Protect user work: do not revert unrelated dirty files or edits you did not make.
8. Inspect the final diff: connect each logical change to its requirement or evidenced problem, and remove obsolete attempts, redundant checks, and temporary workarounds introduced by this task. If the approach changed, apply the replacement checks below to the cumulative task diff. Keep cleanup within confirmed ownership and preserve other work. Verify with the narrowest meaningful command that reaches the required acceptance level.
9. Report changed files, verification evidence, unverified behavior, and residual risk.

## When an Approach Is Replaced

- Establish cleanup ownership from the task history and targeted diff or blame. Limit removal to code introduced by this task or explicitly within our responsibility. Being on the current feature branch, being in a touched file, or appearing unused is not sufficient. Preserve other contributors' work and pre-existing shared behavior; if ownership is uncertain, investigate before deletion. For a necessary change outside that scope, first explain the reason and affected behavior and obtain authorization for that scope unless the user already provided it.
- Review the whole task's changes, including earlier commits and attempts, against the selected design. Trace active callers, parameter writes and reads, and observable effects. References alone do not prove usefulness: fixed neutral values, always-disabled branches, and wrappers that no longer change behavior can be obsolete.
- Within that ownership, remove obsolete parameters, branches, helpers, resources, and stale comments or tests. Revert interface or code-location changes made solely for the abandoned approach when no longer justified. Preserve pre-existing APIs and behavior, and comparison modes or fallbacks the user still requires.
- Keep an old path only for an evidenced current requirement or compatibility contract within the cleanup scope; state the reason when it is not obvious. Investigate uncertain callers or contracts before removal and report unresolved limits. Update the explanation and documentation to describe the final behavior, so obsolete scaffolding is not presented as necessary implementation.

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

Explain the problem, the key implementation choice and its reason, the resulting behavior change, and the supporting verification. For complex changes, point to a few code entrypoints that help a reviewer follow the logic. Keep simple changes to one or two sentences when sufficient.

Apply these checks within the existing implementation and final-diff review. Preserve the low-risk fast path; do not add mandatory plans, documents, separate review stages, or broad test runs solely to satisfy these instructions.

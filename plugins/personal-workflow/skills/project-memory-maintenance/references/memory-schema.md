# Project Memory Schema

Use this schema when maintaining an opted-in project's memory. Adapt headings and file placement to the repository's existing conventions; preserve the semantic distinctions even when the presentation differs.

## Entry Responsibilities

Keep the primary entry concise and current:

- project goal and current phase;
- implemented baseline;
- current milestones or links to them;
- known blockers and limitations;
- next durable task and its acceptance condition;
- links to authoritative design, architecture, decisions, and validation records;
- last evidence-based review date when useful.

Move substantial roadmaps, decisions, validation histories, and module descriptions to established repository documents when the entry becomes difficult to scan. Do not create empty companion documents in anticipation of future content.

## Independent Status Dimensions

Do not collapse these dimensions into one status:

| Dimension | Values | Meaning |
| --- | --- | --- |
| Decision | `Confirmed`, `Rejected`, `Open`, `Superseded` | Whether a choice has been accepted |
| Delivery | `Planned`, `In Progress`, `Implemented`, `Blocked` | Whether the work exists |
| Validation | `Verified`, `Unverified`, `Not Applicable` | Whether the acceptance path was exercised |
| Evidence | `Observed`, `Inferred`, `Unknown` | How the statement is supported |

Use `Done` only when a milestone's stated completion conditions are met. A code implementation may be `Implemented` and `Unverified` at the same time.

## Evidence Priority

When sources conflict, use this order:

1. Current user instruction and read-only boundary.
2. Current task scope and repository instructions.
3. Current runtime, test, or visible acceptance evidence.
4. Current code, configuration, build, and release definitions.
5. Accepted decisions that remain applicable.
6. Project-memory summaries.
7. Historical chats, old reports, and unverified inference.

Describe a conflict instead of changing higher-priority project behavior merely to match stale memory.

## Validation Records

A verification claim should identify enough scope to prevent overgeneralization:

- behavior or target verified;
- command or acceptance path;
- relevant environment or configuration;
- result;
- date when staleness matters;
- remaining unverified environments or behaviors.

Do not treat inspection, compilation, focused tests, runtime behavior, visible results, and persistence as interchangeable evidence levels.

## Portable Content

Shared memory may record portable relative paths, commands, configuration names, and documented setup requirements. Keep actual secrets, personal accounts, machine-local absolute paths, ephemeral endpoints, and local debugger state in repository-approved local storage or ignore mechanisms.

## Multi-Project Repositories

Use the root entry for repository-wide goals and indexes. A subproject may have its own explicitly linked memory entry. Apply the nearest declared entry that owns the current work; do not promote subproject state to repository-wide status without evidence that it applies globally.


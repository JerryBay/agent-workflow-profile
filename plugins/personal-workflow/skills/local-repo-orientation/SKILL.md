---
name: local-repo-orientation
description: Use when opening an unfamiliar checkout, switching computers or branches, resuming a repository after time away, or asking how the current project builds, runs, debugs, and what remains unverified.
---

# Local Repo Orientation

## Core Rule

Reconstruct the current checkout from local evidence. Do not carry machine paths, branch state, or completion claims across repositories without verification.

## Workflow

1. Keep orientation read-only unless the user explicitly asks to persist findings.
2. Inspect repository instructions, authoritative project docs, git status, and the smallest relevant directory map.
3. State the current goal, implemented baseline, unverified validation, and immediate next task.
4. Identify concrete entrypoints: solution/project, executable, working directory, startup arguments, build/test commands, runtime root, resource root, and debugger path when present.
5. Mark unavailable facts as unknown instead of filling them from memory or another computer.
6. Separate portable project facts from machine-local values.

## Project Entry Card

When the user asks to preserve the orientation, use `assets/project-entry-card.md`. Populate only verified fields and keep unknown entries explicit.

Do not create the card automatically. Store machine-specific values in a repo-approved local file or ignore mechanism unless the project owners explicitly want them committed.

## Common Mistakes

| Mistake | Correction |
| --- | --- |
| Reusing an old drive path or launch command | Recheck the current checkout and machine |
| Treating implemented UI or code as live-validated behavior | Report implemented, verified, and unverified states separately |
| Dumping the repository tree | Report only the paths that establish ownership, entrypoints, and the next action |
| Writing local values during a read-only orientation | Report first; persist only after explicit approval |

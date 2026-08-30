# Project Memory Modes

## Bootstrap

Bootstrap requires an explicit user request to establish project memory.

1. Inspect repository instructions and existing project, design, roadmap, ADR, validation, and status documents.
2. Decide whether an existing document can serve as the memory entry without changing its established purpose.
3. If a suitable entry exists, propose or make the smallest opt-in addition allowed by the request.
4. Otherwise adapt `assets/templates/PROJECT.md`; create only the files needed for verified current content.
5. Populate facts from current evidence. Mark missing facts as unknown rather than inventing them.
6. Do not stage or commit the result.

If an unrelated `PROJECT.md` already exists, do not take it over based on its filename. Use repository instructions or user direction to select an entry.

## Maintain

Maintenance is part of a writable task only when the repository is already opted in and the task changes durable facts.

1. Read the relevant memory before making claims about project status.
2. Complete the owning workflow and establish evidence.
3. Assess document impact.
4. If there is no durable impact, leave memory unchanged.
5. If there is impact, update only the directly affected facts and links.
6. Preserve unrelated stale content and report it separately when material.

## Audit

Audit is read-only by default.

1. Define which memory entry, subprojects, status categories, and evidence paths are in scope.
2. Compare claims with current code, configuration, build definitions, tests, logs, and accepted decisions as relevant.
3. Classify each material mismatch as stale, unsupported, ambiguous, or blocked from verification.
4. Report exact document locations, contrary evidence, and the recommended correction.
5. Do not edit until the user separately authorizes synchronization.

## Upgrade

Upgrade requires an explicit request. Follow `migration-rules.md`; do not combine it with ordinary maintenance merely because an older version is observed.


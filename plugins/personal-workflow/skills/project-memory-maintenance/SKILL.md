---
name: project-memory-maintenance
description: Use when the user explicitly asks to initialize persistent project-memory documentation, or when an opted-in repository already has a declared project-memory entry that must be maintained, audited, or upgraded. Do not create project memory merely because a repository is unfamiliar or being inspected.
---

# Project Memory Maintenance

## Core Rule

Create project memory only after an explicit initialization request. In an opted-in repository, read the relevant memory during work and update it only when the current task changes durable project facts and permits file edits.

Project memory is a portable index and status summary, not proof. Current runtime evidence, code, configuration, and build definitions take precedence when they conflict with the memory.

## Detect Opt-In

Treat a repository as opted in only when at least one of these is true:

- A declared memory entry contains `project_memory: true` in YAML frontmatter.
- Repository instructions explicitly identify the project-memory entry.
- The user explicitly identifies an existing document as project memory.

Do not infer opt-in from a filename such as `PROJECT.md` alone.

## Choose a Mode

- **Bootstrap:** The user explicitly asks to establish project memory. Read [references/modes.md](references/modes.md), then use [assets/templates/PROJECT.md](assets/templates/PROJECT.md) only when the repository has no suitable existing structure.
- **Maintain:** An opted-in repository has durable facts affected by the current writable task. Read [references/memory-schema.md](references/memory-schema.md) before editing.
- **Audit:** The user asks whether project memory is current or consistent. Read [references/modes.md](references/modes.md); audit is read-only unless the user separately authorizes fixes.
- **Upgrade:** The user explicitly asks to migrate an older workflow version. Read [references/migration-rules.md](references/migration-rules.md) before editing.

## Maintenance Boundary

For each relevant task, assess document impact; do not force a document change. Durable impact normally includes changes to project phase, milestones, user-visible capability, module ownership or public contracts, build/test/run/release paths, significant decisions, blockers, known limitations, or validation scope.

Formatting, temporary debugging, machine-local state, and internal changes without durable project impact normally require no memory edit.

Current task authorization remains controlling:

- A read-only request may read and report stale memory but may not update it.
- An implementation request may update already opted-in project memory when that update is a direct consequence of the requested change.
- Bootstrap and upgrade require explicit requests for those operations.
- Never stage, commit, push, publish, or release merely because memory was edited.

## Editing Rules

1. Inspect repository instructions, the declared memory entry, relevant authoritative documents, and target-file worktree state before editing.
2. Reuse the repository's established README, docs, ADR, roadmap, or status structure. Do not install a parallel document tree when an existing structure can own the information.
3. Update only facts affected by the current task. Report unrelated stale areas instead of broadening the edit.
4. Preserve user and other-agent changes. Prefer local, mergeable edits; stop and report when content ownership or a safe merge is unclear.
5. Keep machine paths, credentials, account data, temporary endpoints, and local debugger state out of shared memory.
6. Separate implemented, verified, and unverified claims. Record the scope and evidence for verification.
7. Keep the entry concise. Link durable detail instead of turning it into a chronological work log.

## Relationship to Other Workflows

This skill persists conclusions; it does not replace the workflow that establishes them. Repository orientation discovers the checkout, planning establishes requirements and decisions, architecture work establishes ownership and boundaries, implementation changes code, and debugging establishes causes. Record only their evidence-backed, durable conclusions.

Do not rewrite unconfirmed design content, architecture decisions, repository instructions, README content, or user documentation merely to make project memory appear consistent.

## Completion

Report:

- memory files created or updated;
- durable facts changed;
- evidence supporting status and validation claims;
- stale or conflicting information left unchanged;
- relevant behavior that remains unverified.


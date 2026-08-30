# Project Memory Migration Rules

Use these rules only for an explicitly requested workflow upgrade.

## Ownership

Before editing, distinguish:

- workflow-owned markers and structural conventions;
- project-owned facts and prose;
- user or other-agent uncommitted edits;
- semantic changes that require user judgment.

Templates are creation aids, not overwrite sources. Never replace an existing memory document wholesale just because a newer template exists.

## Migration Process

1. Read the current entry, declared workflow version, repository instructions, and target-file worktree state.
2. Identify the smallest changes required by the target version.
3. Preserve project-specific headings and content when their meaning remains valid.
4. Add missing required markers or semantics locally; do not reorder unrelated content.
5. Stop and report when a semantic conversion cannot be inferred safely.
6. Re-run the migration check mentally or mechanically to ensure a second pass would make no further change.
7. Report the previous version, target version, changed structure, preserved custom content, and unresolved manual work.

## Compatibility

Normal maintenance may operate on an older supported structure without upgrading it. When a version is unsupported, report that limitation and request an explicit upgrade rather than silently restructuring the repository.


---
name: evidence-first-local-debugging
description: Use when diagnosing bugs, crashes, debugger issues, missing symbols, broken reopen/save behavior, screenshot prompts, runtime path problems, or user asks for cause without code changes in a local repo.
---

# Evidence-First Local Debugging

## Core Rule

Diagnose from the current local evidence before proposing fixes. Memory and generic experience are routing hints, not proof.

## Workflow

1. Restate the likely failing layer and whether the user requested read-only analysis.
2. Identify the concrete entrypoint: solution/project, startup arguments, executable, working directory, UI command, screenshot prompt, log, asset path, loader, module, or PDB.
3. Inspect the smallest local evidence set that can confirm the route. Prefer `rg`, targeted file reads, debugger/module facts, and existing logs over broad repo scans.
4. Separate observed facts from inference. If an inference depends on stale memory or unverified state, say so.
5. Answer with the exact anchors that matter: file/function, project setting, command, module, resource path, breakpoint, call stack, pointer/value comparison, or persistence hook.
6. If the user asked for no changes, explicitly state that no files or environment settings were modified.

## Read-Only Boundary

When the user says "read-only", asks only for the cause, asks not to change code or environment, or asks whether anything was changed:

- Do not edit files, install packages, change project settings, run formatters, or add instrumentation.
- Use existing code paths, debugger state, logs, screenshots, and read-only commands.
- If a fix is obvious, describe it separately as a possible next step without applying it.

## Common Mistakes

| Mistake | Correction |
| --- | --- |
| Guessing cache/path/version causes before checking the launched target | Inspect the exact solution, executable, working directory, loaded module, and resource path first |
| Treating a visible UI state as persisted state | Trace save, reopen, copy, replay, or serialization hooks |
| Explaining a graph or render issue as one flat dump | Group by functional subgraph or render stage |
| Starting a broad repo search for a debugger question | Start from the configured startup project and runtime directory |

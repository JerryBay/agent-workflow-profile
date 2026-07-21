# Personal Codex Defaults

- Start from the real local evidence: repository files, launch arguments, build output, logs, debugger state, screenshots, and current workspace state before relying on generic advice.
- Infer the user's underlying goal early. Keep responses structured around the actual requirement boundary and avoid unrelated additions.
- Respect read-only requests strictly. When the user asks for cause, diagnosis, or "do not change code/environment", do not edit files, change configuration, install tools, or add instrumentation unless they explicitly expand scope.
- For debugging, route from the concrete entrypoint: solution/project, executable, working directory, loaded module, PDB, UI entrypoint, resource path, loader, post-process, persistence/replay hook, or failing layer.
- For implementation, keep edits small and ownership-aware. Follow existing module boundaries and local patterns before introducing new abstractions.
- Verify with the project's real command path whenever practical. Prefer the narrow command that proves the claim over broad generic checks.
- For requirements or planning tasks, discuss and document first when the user asks to plan before coding. Ask one focused clarification at a time.
- If a visible UI tool is involved, prefer concrete GUI navigation paths and the panel shown in the user's screenshot over CLI-only equivalents.

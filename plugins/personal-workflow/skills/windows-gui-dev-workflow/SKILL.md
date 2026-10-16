---
name: windows-gui-dev-workflow
description: Use when the user asks about Windows development GUI tools such as Visual Studio, Fork, P4V, Unity Editor, RenderDoc, Docker Desktop, debugger panels, screenshots, workspace recovery, submodule status, startup projects, or symbol/module views.
---

# Windows GUI Dev Workflow

## Core Rule

When the task is about a GUI tool, answer in terms of the visible panel and exact UI navigation path. CLI equivalents are secondary unless the user asks for CLI.

## Visual Studio

- Anchor debugger answers to the selected solution, startup project, platform/configuration, startup arguments, working directory, loaded modules, and PDB status.
- For symbol issues, use the Modules window evidence before generic symbol-path advice.
- For debugger-only versus packaged behavior, compare startup args, working directory, project `.user` settings, and runtime bundle paths.
- When IntelliSense or project loading looks wrong, inspect solution/project references and generated build folders before recommending cache deletion.

## Fork

- For submodules, inspect the parent repo commit/file-tree view for the gitlink and open the submodule itself for the checked-out `HEAD`.
- Avoid reducing GUI questions to only `git submodule` commands unless the user asks.

## P4V

- For workspace recovery, prefer P4V navigation: Workspace view, Depot/Workspace tree, Reconcile Offline Work, workspace mapping, and permissions panels.
- If local files exist but source provenance is unclear, inspect packaged metadata and logs first to identify the actual source repo or namespace before sync/reconcile advice.

## Docker Desktop And WSL

- Check Linux containers mode, WSL2 backend, distro integration, and `.wslconfig` resource settings.
- Use `wsl --shutdown` after WSL config changes.

## Unity Editor

- Anchor editor answers to the Unity version, active project, open scene, selected object or asset, and the visible Console, Inspector, Hierarchy, Project, or Package Manager state.
- For import, export, or preview issues, distinguish asset generation, editor import, assembly reload, editor preview, and target-runtime playback; one stage succeeding does not prove the next stage.
- Inspect the actual Console errors, asset paths, serialized references, and package or assembly state before recommending deletion of `Library` or regeneration of the project.

## RenderDoc

- Confirm the captured process, graphics API, frame, build/configuration, and capture timing before drawing conclusions from a capture.
- Use the Event Browser, Pipeline State, Resource Inspector, and shader or texture views to connect a visible symptom to a concrete draw or resource; seeing a draw call alone does not prove correct final output.
- Treat RenderDoc inspection as frame evidence. It does not by itself prove behavior across frames, resource loading, packaged deployment, or the target application's normal runtime path.
- When the task uses the RenderDoc MCP analyzer, keep the GUI capture context and tool analysis aligned; do not replace a missing runtime replay with static capture interpretation.

## Screenshot Handling

If the user's screenshot disproves a guessed path, correct the answer immediately and anchor to the shown panel instead of defending the earlier route.

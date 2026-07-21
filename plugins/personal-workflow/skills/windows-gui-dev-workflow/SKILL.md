---
name: windows-gui-dev-workflow
description: Use when the user asks about Windows development GUI tools such as Visual Studio, Fork, P4V, Docker Desktop, debugger panels, screenshots, workspace recovery, submodule status, startup projects, or symbol/module views.
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

## Screenshot Handling

If the user's screenshot disproves a guessed path, correct the answer immediately and anchor to the shown panel instead of defending the earlier route.

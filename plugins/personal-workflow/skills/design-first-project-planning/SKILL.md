---
name: design-first-project-planning
description: Use when the user wants to discuss requirements, plan before coding, create or update design.md, write a demo spec, brainstorm a feature, or keep implementation blocked until design is agreed.
---

# Design-First Project Planning

## Core Rule

When the user asks to discuss or plan first, keep the session in design/spec mode until the design is accepted.

## Workflow

1. Inspect current project docs and nearby code enough to understand existing structure.
2. Name the active workflow explicitly: design first, no implementation yet.
3. Present related unresolved points together as a concise numbered review list. For each point, state the current assumption, recommended default, and material impact. Ask a single blocking question separately only when its answer determines which remaining questions are relevant.
4. Maintain a compact decision log using Confirmed, Rejected, Open, Evidence, and Next validation.
5. Keep the living document concise. Use the repo's preferred `design.md` if one exists; otherwise use the project's established docs/spec location.
6. For demo work, document demo-level behavior and visible constraints before implementation details.
7. Define visible acceptance criteria before turning the agreed design into an implementation plan.

## Decision Log

- **Confirmed**: decisions the user has accepted.
- **Rejected**: alternatives explicitly ruled out and the reason when it matters.
- **Open**: unresolved questions that can change scope, ownership, or behavior.
- **Evidence**: code, logs, screenshots, docs, or runtime facts supporting a decision.
- **Next validation**: the next concrete check required before implementation or acceptance.

## Output Shape

- Use the user's preferred language and preserve the language of existing design documents.
- Avoid sprawling transcripts. Keep decisions, constraints, and next actions scan-friendly.
- Do not convert discussion into code changes until the user approves moving to implementation.

## Common Mistakes

| Mistake | Correction |
| --- | --- |
| Asking related unresolved points one at a time, or dumping an unstructured batch | Group related points into a concise numbered review list; isolate only a truly blocking question |
| Restyling docs the user did not ask to change | Update the living requirement/design content only |
| Mixing decisions with speculation | Keep Confirmed, Rejected, Open, Evidence, and Next validation distinct |
| Starting implementation with vague completion criteria | Agree on visible acceptance criteria first |

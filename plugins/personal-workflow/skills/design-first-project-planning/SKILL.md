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
3. Ask one focused clarification at a time. Prefer the question that decides scope or ownership.
4. Separate confirmed decisions from open questions.
5. Keep the living document concise. Use the repo's preferred `design.md` if one exists; otherwise use the project's established docs/spec location.
6. For demo work, document demo-level behavior and visible constraints before implementation details.
7. After agreement, turn the design into an implementation plan with clear verification points.

## Output Shape

- Use the user's preferred language and preserve the language of existing design documents.
- Avoid sprawling transcripts. Keep decisions, constraints, and next actions scan-friendly.
- Do not convert discussion into code changes until the user approves moving to implementation.

## Common Mistakes

| Mistake | Correction |
| --- | --- |
| Asking a batch of broad questions | Ask the one question that unblocks the next design decision |
| Restyling docs the user did not ask to change | Update the living requirement/design content only |
| Mixing confirmed decisions with speculation | Keep separate "confirmed" and "open" sections |

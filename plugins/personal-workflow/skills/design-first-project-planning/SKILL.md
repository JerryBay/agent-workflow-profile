---
name: design-first-project-planning
description: Use when planning or implementing a complex feature, resolving material technical choices or user-visible edge cases, or when the user asks to discuss requirements, plan before coding, create or update design.md, or write a demo spec. Keep small, unambiguous, low-risk changes on the fast path.
---

# Design-First Project Planning

## Core Rule

For complex features or material technical choices, keep the session in design/spec mode until the user confirms the concrete technical proposal, even when they asked directly for implementation. Apply the same boundary when the user asks to discuss or plan first. A feature request authorizes investigation and a proposal; it does not settle undisclosed implementation choices.

## When Confirmation Is Required

Require confirmation before introducing or materially changing module boundaries or shared interfaces, state/resource lifetimes, async/concurrent behavior, export/persistence/reload, compatibility, performance-sensitive behavior, or consequential user-visible edge cases. Also require it when plausible approaches differ materially in behavior, authoring workflow, dependencies, or cost.

Judge by the actual behavior and risk, not line count or a keyword match. Merely reading or touching these areas does not trigger the gate. A small, localized, reversible change with clear expected behavior and no material design choice stays on the fast path: no mandatory proposal, plan document, or extra approval. Do not make that exception for a consequential choice merely because its patch is short.

## Workflow

1. Inspect current project docs and nearby code enough to understand existing structure.
2. Name the active workflow explicitly and explain which technical choices require confirmation. Identify decisions already confirmed so they are not asked again.
3. Present related unresolved points together as a concise numbered review list. For each point, state the current assumption, recommended default, and material impact. Ask a single blocking question separately only when its answer determines which remaining questions are relevant.
4. Maintain a compact decision log using Confirmed, Rejected, Open, Evidence, and Next validation. For consequential choices, record whether each constraint comes from the user, verified system behavior, or the proposed solution, along with the alternative considered and its material tradeoffs.
5. Present the technical proposal below before implementation. Keep the living document concise. Use the repo's preferred `design.md` if one exists; otherwise use the project's established docs/spec location. A short proposal may stay in the conversation when a separate document adds no value.
6. For demo work, document demo-level behavior and visible constraints before implementation details.
7. Define visible acceptance criteria and obtain confirmation of the proposal and material open decisions before implementation. The user can approve the presented recommended defaults together; never treat silence or feedback on one point as approval of other unresolved choices.
8. During implementation, pause work affected by a newly discovered material choice or a contradiction with the agreed design. Present the evidence, alternatives, and impact together for confirmation. Continue independent approved work; routine equivalent implementation details need no new approval.

## Technical Proposal

Keep the proposal proportional and omit inapplicable details. Make these points reviewable:

1. **Goal and evidence:** requested behavior, current implementation, scope, and relevant unknowns.
2. **Implementation:** proposed module ownership, entrypoints and execution flow, interfaces, and relevant data/state/lifetimes.
3. **Boundaries and compatibility:** applicable failure, empty/invalid input, ordering, cancellation/cleanup, save/reload, and legacy behavior. State the intended result at important boundaries; do not leave it for coding to decide.
4. **Choices and costs:** materially different viable approaches, the recommendation, and effects on performance, dependencies, representation, or the user's workflow.
5. **Acceptance:** focused checks and any required runtime, visual, or persistence validation, including evidence that cannot yet be obtained.
6. **Decision list:** confirmed choices and numbered open choices, each with its current assumption, recommended default, and material impact so the user can annotate them together.

Before confirmation, use read-only investigation and proposal documentation. Do not write implementation code, tests that commit to an unconfirmed design, scaffolding, or configuration changes that enact it, and do not delegate that work. Preserve already-confirmed decisions; a clear approval of the presented proposal is sufficient to proceed within it.

## Decision Log

- **Confirmed**: decisions the user has accepted. General approval to implement does not establish acceptance of undisclosed technical choices, boundary behavior, extra dependencies, user steps, or authoring restrictions. Preserve prior authorization and do not ask again about impacts already accepted.
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
| Presenting a chosen solution's limitations as user requirements | Identify their source and compare a viable alternative before asking the user to accept them |
| Starting implementation with vague completion criteria | Agree on visible acceptance criteria first |
| Treating "implement this feature" as approval of an unpresented technical design | Investigate, present the concrete proposal and important boundaries, and obtain confirmation |
| Escalating every small edit, or repeatedly asking about settled details | Use the fast path where eligible and carry forward confirmed decisions |

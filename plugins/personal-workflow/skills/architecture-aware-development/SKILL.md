---
name: architecture-aware-development
description: Use when designing or implementing a feature, subsystem, API, refactor, or data-heavy path where module boundaries, cohesion and coupling, data structures, ownership and lifetime, scalability, or performance risks materially affect the result.
---

# Architecture-Aware Development

## Core Rule

Choose the simplest design that satisfies current requirements while preserving cohesive ownership, clear dependency direction, appropriate data structures, and acceptable performance. Do not trade architecture away to stack features, and do not build abstractions for hypothetical futures.

## Workflow

1. Establish the current and near-term requirements, constraints, expected scale, task boundary, and acceptance level.
2. Trace the concrete entrypoint, current owner, data flow and lifetime, invariants, dependencies, and plausible hot paths.
3. Assign behavior to a cohesive owner. Keep contracts minimal, explicit, and directional; avoid leaking internal state or creating circular dependencies.
4. Choose data structures from the dominant reads, writes, lookups, traversals, ordering and uniqueness rules, expected growth, mutability, ownership, lifetime, persistence, and concurrency needs. State the tradeoff when it affects the design.
5. Assess plausible performance risks such as algorithmic complexity, allocation and copying, I/O and serialization, synchronization, or repeated work on a hot path. Measure representative behavior when the risk could affect acceptance.
6. Prefer existing patterns and simple composition. Introduce an abstraction only for a real ownership boundary, stable variation, or multiple concrete call sites. Before adopting a materially different representation or workflow, compare it with preserving the existing one. Consider requirement coverage, authoring freedom, auxiliary dependencies, conversion and maintenance costs, compatibility, and supported performance evidence. Reusing an available path is not sufficient justification if it imposes avoidable burdens on the user. Present consequential tradeoffs before committing to the choice; do not invent alternatives for equivalent internal details.
7. If a local patch would worsen ownership or coupling, make the smallest structural change required for a sound design. Do not broaden the change into unrelated cleanup.
8. Verify through the project's real acceptance path. Use focused benchmarks or profiling only when the performance question is material.
9. Report the chosen owner and boundary, material data-structure and performance decisions, verification evidence, assumptions, unverified behavior, and residual risk.

## Proportionality Decisions

| Question | Default |
| --- | --- |
| Is a new abstraction justified? | Only for a real boundary, stable variation, or multiple concrete consumers |
| Should a new layer or service be added? | Only when it owns a distinct lifecycle, policy, or dependency boundary |
| How much future flexibility should be built? | Leave a cheap, clear seam when useful; do not implement unused branches, modes, or configuration |
| Should the data structure be more sophisticated? | Use the simplest structure that supports known operations and scale without hiding material cost |
| Should performance work happen now? | Address risks that can affect acceptance; measure before complex optimization |
| How broad should a refactor be? | Only broad enough to restore correct ownership, dependency direction, or a safe contract |

## Guardrails

- Do not equate architecture quality with more layers, files, interfaces, or patterns.
- Do not accept a convenient patch that creates misplaced responsibility, hidden global state, or cyclic dependencies.
- Do not claim a performance improvement from intuition alone when representative measurement is practical.
- Do not sacrifice correctness and clarity for micro-optimization when known constraints are already met.
- Revisit the design when requirements, scale, ownership, or evidence changes.

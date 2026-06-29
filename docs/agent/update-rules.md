# Agent Documentation Update Rules

## Update Required

Update both project maps when modules, paths, entry files, public boundaries, major dependencies, or common commands change.

Update the execution protocol when task classification, context expansion, edit safety, verification levels, failure handling, or completion reporting changes.

Update `docs/agent/design-principles.md` only when a durable design decision is adopted or rejected with a primary source and concrete repository impact.

Update plan templates when the resumable task state or review evidence expected from every complex change evolves.

Update this file when repeated Agent mistakes reveal a new maintenance boundary or when generated/protected file rules change.

## TODO Required

Create an evidence-backed TODO instead of guessing when ownership, behavior, terminology, API intent, or cross-module flow cannot be verified.

## Do Not Update

Do not update Agent-facing documents for private implementation details, temporary debugging, formatting-only changes, or helpers with no navigation or execution value.

## Consistency Rule

`docs/agent/project-map.md` and `harness/map/project_map.json` serve different readers but must represent the same repository. Structural changes are incomplete until both are updated.

# Adoption and Customization

## Goal

Adopt the Harness without importing assumptions from this repository into the target project.

## Adoption Sequence

1. Copy `AGENTS.md`, `docs/agent/`, and `harness/`.
2. Replace both project maps with verified target-repository facts.
3. Replace `checks.json` commands with commands that work from the target repository root.
4. Run `eval.sh quick`, then `eval.sh full`.
5. Add project-specific architecture and safety rules only when supported by source or team policy.
6. Commit the Harness and project facts together so future Agents receive a coherent baseline.

## Instruction Layering

| Layer | Contains | Must not contain |
|---|---|---|
| Root `AGENTS.md` | Repository-wide workflow and safety contract | Detailed module implementation knowledge |
| Nested `AGENTS.md` | Subtree-specific commands, constraints, ownership | Rules unrelated to that subtree |
| `docs/agent/` | Maps, protocols, rationale, durable plans | Unverified business assumptions |
| `harness/` | Schemas and executable checks | Hard-coded target-domain examples |

The nearest `AGENTS.md` applies when instructions differ. Avoid copying the root contract into every subtree; document only the delta.

## Configuration Safety

Commands in `harness/evaluation/checks.json` execute with repository permissions. Treat changes to that file like build or CI changes: review the exact command, avoid secrets, and run it in an isolated environment when provenance is uncertain.

## Upgrade Strategy

Until a versioned installer exists, upgrades are explicit three-way merges:

1. Compare the new core protocol and schemas.
2. Preserve verified project facts and local nested instructions.
3. Apply schema migrations deliberately.
4. Run structural and project verification before accepting the upgrade.

Never overwrite project-specific maps or verification commands blindly.

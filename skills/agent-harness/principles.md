# Principles behind the harness

Why each convention exists. Read this when adapting the harness to an unusual
project, or when tempted to skip a block. The `SKILL.md` tells you *what* to
build; this explains *why*, so you can adapt rather than cargo-cult.

## 1. Fact priority beats prose

An agent's failure mode is trusting a confident-sounding but stale doc over the
code. A single explicit priority order ("code > stable specs > active docs >
drafts") gives it a deterministic tiebreaker. Everything downstream depends on
this: without it, the other seven blocks can actively mislead.

Corollary: docs never claim a capability the code lacks. A doc describing an
unimplemented feature is worse than no doc — it manufactures false confidence.
Mark unbuilt things `draft`/`planned` explicitly.

## 2. One authoritative location per rule

Every rule, fact, or decision lives in exactly one place; everything else links
to it. Duplication guarantees divergence — the moment a rule appears in three
files, two of them will silently go stale. Linking costs one hop and keeps a
single source of truth.

This is why `AGENTS.md` is a router, not a manual: it points, it does not
restate.

## 3. Progressive disclosure

Context is scarce and shared. Front-load only what every task needs (entry
point, fact priority, where-to-find-X); push detail behind links the agent
follows on demand. A 40-line `AGENTS.md` that routes well beats a 600-line one
that the agent partially reads and half-applies.

Keep reference links one level deep from the entry doc — deeply nested chains
get partially traversed.

## 4. Doc sync is a step, not a virtue

"Keep docs updated" as an aspiration fails. As a mechanical lookup it works:
the Doc Sync Matrix says *given this change, edit exactly these docs*. Treat it
like a compiler rule, not etiquette. Most observed drift traces to this matrix
being absent or unconsulted — so it is the first thing to add and the first
thing to check in an audit.

## 5. Proportionality

The harness scales down. A three-file script does not need ADRs and execution
plans; forcing them produces ceremony nobody maintains, which trains the team to
ignore the harness entirely. Climb the Adoption Ladder only when a real need
appears. Under-building is recoverable; an abandoned over-built harness is
actively harmful because it looks authoritative while being ignored.

## 6. Append-only decisions

Architecture decisions (ADRs) are never edited in place — a superseded decision
is recorded by a *new* ADR that references the old one. This preserves the
"why" trail: a future agent can see not just the current rule but what it
replaced and the reasoning, which prevents re-litigating settled choices.

## 7. Capture traps once

A pitfall solved but not recorded gets re-derived — expensively — by the next
agent. `pitfalls.md` (symptom → root cause → fix) converts a painful debugging
session into a one-line future lookup. Add an entry the first time a non-obvious
trap costs real time; do not pre-populate hypothetical ones.

## Anti-patterns (expanded)

| Anti-pattern | Why it fails | Instead |
|---|---|---|
| Copy another repo's harness content verbatim | Encodes the *other* project's reality; rules won't match the code | Copy the *structure* (templates); fill from this repo |
| Aspirational rules | Agents detect the mismatch with code and stop trusting all docs | Only write rules the code actually follows; make violations visible |
| `AGENTS.md` as a manual | Burns context, gets partially read | Route in ≤1 screen; detail behind links |
| Duplicating a rule across files | Guaranteed divergence | Single authoritative location + links |
| All 8 blocks on a tiny repo | Ceremony nobody maintains → whole harness ignored | Adoption Ladder |
| Estimate markers in fact fields (`~`, `TBD`) | Reads as fact, silently wrong | Real value, or explicitly marked unknown |
| Editing an accepted ADR in place | Loses the decision trail | New superseding ADR |

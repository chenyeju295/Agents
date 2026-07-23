---
status: active
kind: plan
---

# <NNNN>-<short-kebab-name>

Execution plan for a complex or multi-session task. Carries state across
agents, threads, and sessions so nothing relies on chat history. Update this
same file continuously — do not create a new copy each session.

Frontmatter `status` is authoritative. Valid values:

| Status | Meaning |
|---|---|
| `draft` | Proposed scope, not yet selected for execution |
| `active` | Currently being executed — only one current active plan for the task |
| `paused` | On hold; document the resume condition |
| `completed` | Acceptance met; verification evidence recorded — historical, do not reopen |

## Goal

<The outcome, in one or two sentences. What "done" looks like.>

## Scope

<In scope / out of scope. Which parts of the codebase this touches.>

## Acceptance Criteria

- [ ] <verifiable condition 1>
- [ ] <verifiable condition 2>

## Progress

<Running log of what is done and what is next. Newest at the bottom. Keep it
factual — this is the resume point for the next session.>

## Decisions

<Choices made during execution and their rationale. Promote durable
architecture choices to an ADR in docs/decisions/.>

## Verification

<What has been run and its result. Anything not yet verified MUST be marked as
such — never imply an unrun check passed.>

## Open Questions

<Unresolved blockers or decisions needed. Note who/what unblocks each.>

<!--
Conventions:
- Filename: NNNN-short-kebab-name.md.
- Create when a task spans multiple modules/sessions or has unresolved
  decisions. Simple, single-session edits do not need a plan.
- Select a plan only when the task continues it or unfinished scope clearly
  matches. Update only the selected active plan while executing.
- A completed plan is historical evidence; create a follow-up plan for new work.
-->

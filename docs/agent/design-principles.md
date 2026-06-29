# Harness Design Principles

## Purpose

This document records the external engineering ideas intentionally adopted by this repository. It is rationale, not another layer of mandatory task instructions.

## Principles

### 1. The entry file is a map, not an encyclopedia

Keep `AGENTS.md` short and stable. Place detailed, versioned knowledge in discoverable repository documents and load it progressively.

Source: [OpenAI — Harness engineering](https://openai.com/index/harness-engineering/).

### 2. Constraints should become executable invariants

Documentation alone drifts. Important structure, boundaries, configuration, and documentation integrity should be checked mechanically with actionable failures.

Source: [OpenAI — Harness engineering](https://openai.com/index/harness-engineering/).

### 3. Plans are durable engineering artifacts

Complex work should produce a specification, an implementation plan, verifiable milestones, and a decision trail. The repository must carry enough state for another Agent to resume without chat history.

Sources: [OpenAI — Harness engineering](https://openai.com/index/harness-engineering/), [GitHub Spec Kit](https://github.com/github/spec-kit).

### 4. Instructions support local specialization

Use a repository-wide root contract and nested `AGENTS.md` files only where a subtree needs different commands or constraints. The nearest applicable instruction file takes precedence.

Source: [AGENTS.md open format](https://agents.md/).

### 5. Agent-facing interfaces deserve deliberate design

Commands and feedback should be compact, unambiguous, and actionable. Successful empty output and failures should both be explicit; tools should avoid flooding context with irrelevant matches.

Source: [SWE-agent — Agent-Computer Interface](https://github.com/SWE-agent/SWE-agent/blob/main/docs/background/aci.md).

### 6. Core and project policy stay separate

The portable core defines protocol and schemas. A target repository supplies facts, commands, architecture constraints, and optional local skills. Generic defaults must not pretend to know project semantics.

## Deliberate Non-Goals for Stage 0

- No model provider integration.
- No autonomous multi-Agent orchestration.
- No mandatory full specification workflow for small changes.
- No central service or external knowledge dependency.
- No auto-generated business semantics from filenames.

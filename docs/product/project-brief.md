# Project brief

## Problem

AI agents can construct useful wallet actions, but giving an agent an
unrestricted signing key makes the agent, its prompt, its dependencies, and its
runtime part of the wallet's security boundary. A compromised or mistaken agent
can then propose an action outside the owner's intent.

## Product hypothesis

An owner can delegate narrowly scoped Safe capabilities to an AI agent without
revealing the complete policy, provided that:

- the policy is committed independently of the agent;
- every executed action is bound to an unforgeable proof of policy compliance;
- `ZkPolicySafeModule` verifies the proof before Safe execution; and
- revocation, replay resistance, and failure behavior are explicit.

This is a hypothesis, not yet a claim about a production-ready security system.

## Intended users

- Safe and smart-account developers adding constrained agent permissions;
- agent developers who need useful wallet access without custody of unrestricted
  authority; and
- security researchers evaluating proof-bound authorization designs.

## Initial discovery scope

- model a Safe action and an owner-defined permission policy;
- bind an action, policy commitment, Safe address, chain, and replay protection
  into a proof statement;
- verify the proof in `ZkPolicySafeModule` before the Safe execution boundary;
- demonstrate both an allowed action and a denied action; and
- document the trust model, privacy properties, and operational failure modes.

## Out of scope for the first proof of concept

- claiming that an LLM or agent is itself trustworthy;
- supporting arbitrary chains, wallets, and proving systems simultaneously;
- production custody, audited security, or mainnet deployment;
- hiding every part of an action or policy; and
- optimizing prover cost before the security statement is clear.

## Success criteria for the first vertical slice

1. A reader can state exactly what the proof proves and does not prove.
2. An allowed action executes from a real Safe through an enabled module in a
   local or test environment.
3. A policy-violating, expired, modified, or replayed action is rejected.
4. Tests cover the happy path and each documented rejection condition.
5. The demo can be reproduced from a clean checkout using documented commands.

## Open product decisions

- Which first Safe action creates the clearest demonstration?
- Which policy constraints are essential for the first vertical slice?
- Which policy fields should remain private, if any?
- Is the first audience protocol developers, application developers, or a
  security-focused demo audience?
- What is the smallest useful revocation experience?

Resolve consequential choices through an ADR rather than silently narrowing the
scope in implementation.

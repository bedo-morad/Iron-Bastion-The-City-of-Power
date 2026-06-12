# AGENTS.md

## Read First — Canonical Doc

**`CLAUDE.md` is the single source of truth for this repo.** Open and read it in full at the start of every session before doing anything else. It documents the engine & entry point, autoload singletons, the player / enemy / combat / level / HUD / scene-transition systems, physics layers & input actions, build & run, and the project vision/roadmap.

Keep all architecture and project documentation in `CLAUDE.md` only — **do not duplicate it here**, so the two never drift apart (this file and `CLAUDE.md` previously drifted, which is why the repo now has one canonical doc).

> For Codex and other AGENTS.md-aware tools: this file intentionally defers to `CLAUDE.md`. The behavioral rules below are mirrored from it because they are stable and apply to every tool/agent — but `CLAUDE.md` still wins if they ever disagree.

# CRITICAL RULES - MUST FOLLOW

## RESPONSES

- Keep responses concise and to the point - unless the user asks otherwise

## Communication Preferences

- Ask for clarifications on ambiguous problems rather than guessing.
- Be direct and honest. Keep responses concise unless asked otherwise.

## PLANNING MODE

- Always ask clarifying questions
- Never assume design, tech stack or features
- Use deep-dive sub-agents to assist with research
- Use deep-dive sub-agents to review the different aspects of your plan before presenting to the user

## CHANGE / EDIT MODE

- Never implement features yourself when possible - use sub-agents!
- Identify changes from the plan that can be implemented in parallel, and use sub-agents to implement the features efficiently
- When using sub-agents to implement features, act as a coordinator only
- Use the best model for the task - premium models for complex tasks (like coding) and mid-tier models for simpler tasks, like documentation
- After completing features (large or small), always run commands like lint, type check and next build to check code quality

## TESTING

- Use any testing tools, libraries available to the project for testing your changes
- Never assume your changes simply work, always test!
- If the project does not have any testing tools, scripts, MCP tools, skills, etc. available for testing, ask the user whether testing should be skipped.

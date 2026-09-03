# 4growth AI Skills

Skills are reusable folders containing instructions, scripts, examples, templates, and other resources that help AI agents perform specific tasks consistently.

At 4growth, we use skills to capture company knowledge and repeatable workflows so they can be reused across the AI tools and models we work with, including **OpenAI, Claude, and Gemini**.

A skill can teach an AI agent how to:

* follow 4growth development conventions;
* work with our Unity projects and tooling;
* review or generate code according to our standards;
* create documentation using our preferred structure and tone;
* perform testing and quality checks;
* work with specific products such as LearnStrike and MicroGames;
* execute recurring technical or business workflows.

Instead of repeatedly explaining the same context in prompts, we capture that knowledge once inside a skill.

## About This Repository

This repository contains the shared **4growth AI Skills**.

The goal is to create a central place for instructions and workflows that we want to reuse across projects, developers, and AI platforms.

Skills can range from small sets of instructions to more advanced packages containing:

* `SKILL.md` instructions;
* scripts and utilities;
* templates;
* examples;
* reference documentation;
* test cases;
* supporting resources.

Each skill lives in its own folder and should be as self-contained as possible.

Example:

```text
skills/
├── unity-code-review/
│   ├── SKILL.md
│   ├── examples/
│   └── scripts/
│
├── microgames/
│   ├── SKILL.md
│   └── references/
│
└── technical-documentation/
    ├── SKILL.md
    └── templates/
```

## Why We Use Skills

AI models are powerful, but without the right context they do not automatically know how we work at 4growth.

Skills allow us to turn that context into reusable instructions.

For example, instead of explaining our Unity conventions every time we ask an AI agent to review code, we can create a `unity-code-review` skill containing those conventions once.

This gives us:

* more consistent results;
* less repeated prompting;
* shared knowledge between developers;
* easier onboarding;
* reusable workflows across projects;
* easier testing and improvement of AI-assisted processes.

Skills also allow knowledge to live in the repository instead of only inside individual prompts or chat histories.

## AI Platforms

We currently work with multiple AI platforms, including:

* **OpenAI / ChatGPT / Codex**
* **Anthropic Claude / Claude Code**
* **Google Gemini**

The exact way a platform discovers or loads skills can differ.

Because of this, the skills in this repository should be written as **platform-independent 4growth knowledge wherever possible**.

Platform-specific configuration can be added when needed, but the core instructions should remain reusable.

Conceptually:

```text
                    ┌──────────────┐
                    │ 4growth Skill│
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
          OpenAI        Claude        Gemini
        / Codex      / Claude Code
```

This prevents important company knowledge from becoming tied to a single AI provider.

## Creating a Skill

A basic skill is simply a folder containing a `SKILL.md` file.

For example:

```text
skills/my-skill/
└── SKILL.md
```

A basic `SKILL.md` could look like this:

```markdown
---
name: my-skill
description: Explains what this skill does and when an AI agent should use it.
---

# My Skill

Describe the task, context, and expected behaviour.

## Instructions

- Instruction 1
- Instruction 2
- Instruction 3

## Examples

### Example 1

Describe an example task and the expected result.

### Example 2

Describe another situation in which the skill should be used.

## Guidelines

- Guideline 1
- Guideline 2
- Guideline 3
```

At minimum, a skill should clearly explain:

* **what** the skill does;
* **when** it should be used;
* **how** the task should be performed;
* **what a good result looks like**.

## Skill Design Principles

### Keep Skills Focused

Prefer a skill with one clear responsibility over a large skill that tries to explain everything about 4growth.

For example:

```text
unity-code-review
unity-testing
microgames-development
technical-documentation
```

is generally easier to maintain than:

```text
everything-about-4growth
```

### Separate Knowledge From Tasks

Some information describes our environment, while other instructions describe how to perform a task.

Where possible, keep these concepts separated so information can be reused by multiple skills.

For example:

```text
references/
└── microgames-architecture.md

skills/
├── microgames-code-review/
└── microgames-feature-development/
```

Both skills can use the same architectural reference.

### Include Examples

Examples are often one of the most effective ways to make AI behaviour predictable.

Include examples when:

* formatting matters;
* there are common mistakes;
* multiple interpretations are possible;
* 4growth uses conventions that differ from common defaults.

### Make Instructions Testable

Avoid vague instructions such as:

> Write good code.

Prefer:

> Do not introduce new dependencies unless necessary.
> Keep public APIs backwards compatible unless the task explicitly requires a breaking change.
> Add or update automated tests when behaviour changes.

The more concrete the instruction, the easier it is to verify whether a skill works correctly.

## Suggested Skill Categories

As the repository grows, skills can be grouped into categories such as:

```text
skills/
├── development/
│   ├── unity/
│   ├── web/
│   └── backend/
│
├── products/
│   ├── learnstrike/
│   └── microgames/
│
├── quality/
│   ├── code-review/
│   └── testing/
│
├── documentation/
│
├── research/
│
└── communication/
```

The structure should stay practical. We should only introduce additional categories when they actually make the repository easier to navigate.

## Platform-Specific Instructions

Some capabilities will inevitably depend on a specific platform.

When that happens, keep the general skill vendor-neutral and place platform-specific instructions separately where possible.

For example:

```text
unity-code-review/
├── SKILL.md
├── platforms/
│   ├── openai.md
│   ├── claude.md
│   └── gemini.md
└── references/
```

This allows us to improve support for one platform without duplicating the complete skill.

## Testing Skills

Skills should be treated like other reusable tooling: changes can affect their output.

Before relying on a skill for important work:

1. Test it with realistic tasks.
2. Try different AI models where relevant.
3. Check whether important instructions are consistently followed.
4. Add examples for situations where the skill performs poorly.
5. Keep the instructions as simple as possible.
6. Update the skill when our own processes change.

Different models may interpret the same instructions differently, so identical behaviour across OpenAI, Claude, and Gemini should not automatically be assumed.

## Contributing

When adding or updating a skill:

1. Keep the scope clear.
2. Prefer reusable 4growth knowledge over model-specific prompting tricks.
3. Include enough context for someone outside the original project to understand the skill.
4. Add examples for non-obvious behaviour.
5. Avoid duplicating information that already exists elsewhere in the repository.
6. Test the skill with realistic tasks.
7. Keep platform-specific instructions separated when possible.

## Goal

The goal of this repository is not simply to collect prompts.

It is to build a reusable **AI knowledge and workflow layer for 4growth**.

Over time, the repository should capture more of the way we develop software, build products, test our work, document decisions, and collaborate.

This gives OpenAI, Claude, Gemini, and future AI tooling a shared foundation for working the **4growth way**.

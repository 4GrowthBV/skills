---
name: game-toolkit-microgame-system
description: Explains and traces the 4growth game-toolkit microgame runtime, from launch payload and identifier routing through content loading, mechanic composition, rounds, scoring, and completion. Use for microgame architecture, lifecycle, content loading, mechanic development, or troubleshooting a microgame from launch to result; use the dedicated chat, Firebase, or Unity Cloud backend skill when those integrations are the main subject.
---

# Game Toolkit Microgame System

Explain or modify the microgame subsystem from current repository evidence. A microgame is a configured instance of a reusable mechanic, not a standalone game or scene.

## Mental model

Keep these concepts distinct:

- **Mechanic:** reusable gameplay behavior and its scene, installer, controller, state, sequences, and view controllers under `Assets/Toolkit/Mechanics`.
- **Microgame instance:** content selected by a `micro_game.identifier`, normally stored as an Addressable `MissionSettingBase` asset.
- **Mission settings/package:** rounds, questions, timing, scoring behavior, localization, expansion data, takeaways, and content references.
- **Theme package:** reusable presentation, prefabs, and the surrounding background, introduction, foreground, debriefing, and settings scenes.
- **Launch payload:** player, organisation, session, battle, module, environment, context, star thresholds, integration data, and per-launch `extra_data`.

Read [references/microgame-architecture.md](references/microgame-architecture.md) for the detailed lifecycle, source map, routing, loading invariants, and extension checklist.

## Workflow

1. Locate the Unity project root containing `Assets`, `Packages`, `ProjectSettings`, and `GameToolkitCloudCodeModule`.
2. Identify the launch path and inspect `GamificationPlayerController.WaitForInitAndProcessMicroGame` plus the current `MicroGamePayload` definition.
3. Classify the identifier before tracing further:
   - ordinary mechanic: follow `MicroGameLoader.LoadMicroGame`;
   - Story, Social Game, Triviant, Onboarding, Chat, or test mode: follow its dedicated loader and starter instead.
4. For an ordinary mechanic, trace all three phase-one inputs: the identifier-addressed mission settings, selected theme package, and Firebase content cache. Do not describe them as one asset bundle.
5. Inspect `StartMicroGameMono` for runtime package generation, content application, seed selection, localization, and the handoff to `FadeInOut.MicroGameTransition`.
6. Inspect the shared installer and the selected mechanic's `Installer`, `Controller` or `GameController`, and mission-settings type. Follow Zenject bindings rather than assuming behavior from filenames.
7. Trace the shared runtime through `MissionController`, `RoundManager`, the mechanic controller, `MicroGameController`, and `GamificationPlayerManager.StopMicroGame` until the result reaches the host or API.
8. When loading behavior matters, verify the two-phase config/sprite strategy and the rolling round-asset window in the current code and `Documentation/split-loading-architecture.md`.
9. Prefer source code and tests over documentation when they disagree. Treat Addressables metadata and Unity YAML as wiring evidence, not proof that a dormant asset is used at runtime.

## Modification guidance

When changing or adding a mechanic:

- Preserve the separation between mechanic behavior, mission content, theme presentation, and launch context.
- Start from the closest existing mechanic and inspect its full installer-to-round-completion path before editing.
- Add identifier routing only when a new mission-settings type genuinely needs it; the current router uses explicit prefix checks rather than automatic discovery.
- Keep runtime-loaded mission content isolated from the packaged template. Do not mutate the authored template asset as session state.
- Preserve first-round readiness gating, next-round preloading, previous-round release, and Addressables handle cleanup.
- Re-run the repository's sprite-to-`LazySprite` migration workflow when newly authored sprites must become independently loadable Addressables.
- Update focused EditMode or PlayMode coverage when observable behavior changes. Do not claim tests or builds pass unless they were run in the current checkout.

## Response guidance

- Answer in the user's language and lead with the concrete runtime flow or diagnosed boundary.
- Explain the reusable-platform model before discussing a specific configured product.
- Name repository-relative classes and files that support important claims.
- Use a small lifecycle diagram when it makes multiple stages easier to understand.
- For troubleshooting, identify the last successful boundary: payload receipt, routing, phase-one loading, content application, scene injection, intro/countdown, round execution, result submission, or return transition.
- Clearly separate ordinary mechanics from Story, Social Game, Triviant, Onboarding, and Chat, which share the launch shell but have specialized startup paths.

## Safety and boundaries

- Keep explanations public-safe: never reproduce real payloads, tokens, player or organisation identifiers, internal URLs, bucket names, customer content, or deployment configuration. Use neutral placeholders.
- Do not inspect live services, Firebase data, production payloads, or deployed configuration unless explicitly requested and authorized.
- Use the Firebase skill for Firebase authentication, Storage, Functions, or FCM internals; use the Unity Cloud backend skill for generic protected API calls; use the AI chat-streaming skill for streamed chat transport.
- Do not infer deployed behavior merely because code or an Addressable asset exists in the checkout.

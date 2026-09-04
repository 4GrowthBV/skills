---
name: game-toolkit-overview
description: Explains the global architecture and structure of the 4growth game-toolkit Unity project. Use for project overviews, onboarding, runtime flows, subsystem boundaries, repository navigation, or questions about where functionality lives. Do not use for unrelated Unity projects.
---

# 4growth Game Toolkit Overview

Give an evidence-based overview of the `4GrowthBV/game-toolkit` repository without attempting to inventory every asset.

## Workflow

1. Locate the Unity project root. It contains `Assets`, `Packages`, `ProjectSettings`, and `GameToolkitCloudCodeModule`.
2. Read [references/project-map.md](references/project-map.md) for the stable architectural map.
3. Verify details that can drift before reporting them:
   - Unity version: `ProjectSettings/ProjectVersion.txt`
   - product and application version: `ProjectSettings/ProjectSettings.asset`
   - active build scenes: `ProjectSettings/EditorBuildSettings.asset`
   - Unity dependencies: `Packages/manifest.json`
   - Gamification Player package version: `Packages/com.4growth.gamification-player-app-for-unity/package.json`
   - backend dependencies and targets: the relevant `.csproj` and `package.json` files
4. For a requested subsystem, inspect its actual installer, manager, or entry point in addition to the project map. Prefer source code over descriptive documentation when they disagree.
5. Keep the operation read-only unless the user explicitly asks for a project change.

## Response guidance

- Answer in the user's language.
- Lead with the project's purpose: a reusable Unity platform for branded gamified learning applications, not one standalone game.
- Distinguish the reusable platform from the product currently selected in Unity settings.
- Cover the main layers, a short end-to-end runtime flow, important directories, and development/testing entry points.
- Link or name the concrete files that support important claims.
- Scale the answer to the question. A general overview should be concise; onboarding or subsystem questions may go deeper.
- State uncertainty when a runtime or deployment detail cannot be verified locally.

## Boundaries
- Do not treat `Library`, `Temp`, `Obj`, `Build`, `Builds`, `Logs`, or `UserSettings` as authored architecture.
- Separate bundled third-party packages, plugins, and demo scenes from 4growth-owned systems.
- Do not infer active functionality merely because a scene or asset exists; check build settings, installers, references, or Addressables configuration.
- Do not hardcode version numbers, active scene lists, dependency versions, environment catalogs, or customer-specific branding in an answer without checking the current repository.
- Do not browse external services unless the user asks for current external information that the repository cannot establish.

---
name: game-toolkit-configuration-editor
description: Explain, extend, or debug the 4growth game-toolkit MicroGames configuration editor built with Unity UI Toolkit. Use for its mission and round settings, nested value objects, localisation, random pools, CSV import/export, assets, themes, or save/reload behavior. Not for unrelated Unity editors or the legacy WebView implementation.
---

# Game Toolkit Configuration Editor

Work from the current implementation of the runtime MicroGames configuration overlay. Despite its name, this is a `MonoBehaviour` with a `UIDocument`, not a Unity `EditorWindow`.

## Workflow

1. Locate the game-toolkit checkout containing `Assets/Toolkit/ManagerGeneratedContent`. Paths below are relative to that checkout, not this skills repository.
2. Read [references/editor-architecture.md](references/editor-architecture.md) for the source map, ownership of editable data, and persistence constraints.
3. Inspect the relevant current source and tests. Trace an interaction from its UXML element or dynamically created control through `ConfigurationEditorView`, the controller event handler, the authoritative data, and serialization/reload.
4. For explanations, stay read-only. For requested changes, keep the edit at the owning layer and preserve existing mechanic-specific behavior. Do not turn a UI request into a migration of the editor framework or backend.
5. Validate behavior at the affected boundary. For content changes, exercise edit, save, and reload; a changed label or in-memory value does not establish persistence. For visual changes, inspect the actual rendered UI and Unity import/Console output when Editor access is available. Report unavailable validation explicitly.

## Essential constraints

- `ConfigurationEditorController.cs` and `ConfigurationEditorView.cs` implement the UI Toolkit editor. The neighboring `OverlayController.cs`, `LocalServer.cs`, and `InstallPages.cs` belong to the older WebView path; the shared scene-name constant alone does not identify the running implementation. Check scene component GUIDs when wiring matters.
- Keep the authored template separate from the editable runtime mission package. Preserve runtime isolation and recursive MIX serialization/restoration through the existing managers.
- Localisation edits live in the controller DTO; pool edits live in its per-round, per-language CSV rows; images live in `MicroGameContent`. Rebuilding these from template objects can silently discard edits.
- Preserve persistent value-object GUIDs and full asset metadata identity. Display names and row positions are insufficient identifiers for nested or shared content.
- Keep the `Original` context save guard, concurrent-save guard, error state, and unsaved-change handling. Saving calls a cloud replacement workflow, so use test doubles for persistence checks unless a live save is part of the authorized request.
- Match existing UXML queries, USS classes, dynamic view construction, and organisation theme application. Inspect C# theme overrides as well as USS when a style change appears ineffective.
- Keep examples public-safe: use synthetic content and placeholders, not customer text, credentials, live payloads, organisation identifiers, or service configuration.

## Task routing and validation

- **Missing or incorrect control:** inspect `PopulateMissionSettings`, `PopulateRounds`, `AddMechanicSpecificRoundSettings`, or `PopulateValueObjects`, then its view event and controller handler.
- **Lost text or language edits:** trace `HandleLocalisationValueChanged` and `BuildMicroGameContentAsync`; distinguish localisation keys from translated pool cells.
- **Pool structure/import issue:** inspect the expansion's structure declarations, the selected renderer, `PoolCsvImportValidator`, and cross-language synchronization before changing table indexing.
- **Missing/wrong image:** trace cache loading, template fallback, round/MIX metadata, asset identity, deletion tracking, and `CopyAllImages`.
- **Save/reload failure:** trace the configuration, localisation, expansion, and image branches separately, then upload preflight and cloud storage. Treat `CONFIGURATION-FLOW.md` as background; source and tests take precedence where it differs.

Use existing focused tests under the overlay's `Tests/Editor` and `Tests/PlayMode` folders. The reference lists suite entry points. Do not claim Unity tests pass based on static inspection or the skill validator.

For answers, lead with the relevant data flow or concrete finding, name the supporting source files, and separate observed behavior from assumptions about deployed content.

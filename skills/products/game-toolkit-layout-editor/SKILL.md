---
name: game-toolkit-layout-editor
description: Explain, extend, or debug the visual round layout editor opened by Edit Layout in the 4growth game-toolkit configuration editor. Use for its canvas, object inspector, dragging, mechanic mappings, pool previews, text editing, copy/reset, undo/redo, and layout persistence. Not for general Unity scene layout or UI Builder.
---

# Game Toolkit Layout Editor

Work from the runtime UI Toolkit `RoundVisualEditor` inside the MicroGames configuration overlay. It previews authored round layouts and edits their existing data; it is not a Unity `EditorWindow` or a running gameplay simulation.

## Workflow

1. Locate the game-toolkit checkout containing `Assets/Toolkit/ManagerGeneratedContent/MicroGamesConfigurationOverlay`. Source paths in this skill are relative to that checkout, not this skills repository.
2. Use [references/layout-editor.md](references/layout-editor.md) for the source map and the affected mechanic. Verify the current implementation before relying on a mapping.
3. Trace the relevant interaction from the dynamically created control through its controller callback, the owning round/localisation/pool data, and the save/apply or gameplay consumer. For explanations, stay read-only; for requested changes, edit the owning layer.
4. Validate the affected behavior using the reference's test entry points. A changed preview does not prove persistence or gameplay parity. Report which Unity tests, save/reload checks, and visual checks actually ran.

## Essential constraints

- **Preserve the data model.** Layout edits use existing serialized fields on the runtime round and value objects. Extend the explicit mappings and gameplay consumers when needed; do not introduce a parallel layout document or read randomized runtime getters to populate the editor.
- **Preserve round ownership and identity.** Keep `EnsureRuntimePackageFromTemplate` and `IsolateSharedObjects` before editable sessions. Shared objects are detached with their persistent GUIDs intact. Within a round, all representations of the same ID receive the edit; stage membership is separate. Do not generate replacement IDs or write into the authored template.
- **Keep the editability gates.** `SupportsRuntimePackageGeneration` and `RoundVisualEditor.Supports` govern availability. `Original` context and deleted rounds can be previewed read-only. Saving blocks mutations. A MIX with a child that cannot generate runtime packages remains blocked even if another child has a supported round type.
- **Respect coordinates and field types.** The canvas uses a 1920 x 1080 reference area. Authored positions are centre-origin with Y up; UI coordinates have Y down. Use `ToCanvas`, `FromCanvas`, and `canvas.WorldToLocal` for scaled pointer input. Preserve `Vector2` precision and `Vector2Int` rounding. `(0, 0)` sizes mean native size only for fields allowed by `NativeSize`; mixed-zero or negative dimensions are invalid.
- **Keep history at the controller session level.** Route mutations through `LayoutHistory` and the existing callbacks so dirty state, undo/redo, gesture grouping, and reopening work together. Closing the layout keeps session changes; Save in the main configuration editor persists them.
- **Separate preview content from edits.** Pool samples do not change CSV rows or assign gameplay content. `TextOwnedByPool` decides whether text is editable here; non-pool text changes go through `ChangeLayoutText` into the selected language in `localisationData`. Shared localisation keys still update together. Route pool-owned content and complex LocateAndAnswer positions to the pool editor.
- **Copy/reset only layout.** Preserve the preflight compatibility checks and independent snapshots in `TryCopyLayout`. Copy and reset retain destination content, image references, answers, IDs, and enabled states. Reset uses the original matching template round, the existing confirmation modal, and undo history; it still needs Save for persistence.
- **Keep assets and themes consistent.** Resolve cached images with round, MIX child, language, and deletion identity intact. Pair layout asset loading with `ReleaseRoundLayoutAssets`. Inspect dynamic C# styles and organisation theme application as well as USS.

Use synthetic fixtures and public-safe examples. Persistence tests should use the existing in-memory fixtures/test doubles unless the task includes a live cloud save.

## Task routing

| Request | Start here |
| --- | --- |
| Missing Edit Layout button or read-only inspector | Controller `PopulateRounds`, `OpenRoundLayout`, capability flags, and deleted/context state |
| Wrong position, drag, size, or object selection | `Item`, `CollectItems`, `CollectSlots`, `Render`, `FitCanvas`, `DragManipulator`, and the field's mechanic mapping |
| Missing inspector field or new mechanic support | `RoundVisualEditorMappings`, `RebuildInspector`, mutation validation, serialization/apply, and the gameplay renderer |
| Wrong text or pool sample | `LayoutTextKey`, `ChangeLayoutText`, `TextOwnedByPool`, `PoolSections`, and the relevant `Update*Pool` method |
| Copy/reset/undo leaks into other rounds | `IsolateSharedObjects`, `GetLayoutHistory`, `TryCopyLayout`, template round resolution, and fresh configuration apply |
| Preview differs from gameplay | Prefab variant/pivot, theme defaults, cached artwork, and the mechanic's actual view controller |
| Layout looks right but reload loses it | Controller `BuildMicroGameContentAsync`, `MicroGameConfigurationManager.SetContent`, configured FullSerializer, mechanic `Apply`, and recursive MIX ownership |

For editor-wide loading, pool import, cloud upload, or asset management beyond this feature, consult the sibling [configuration-editor skill](../game-toolkit-configuration-editor/SKILL.md).

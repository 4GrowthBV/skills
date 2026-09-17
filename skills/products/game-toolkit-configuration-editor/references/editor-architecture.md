# Configuration editor source map

All paths are relative to the game-toolkit Unity project. Recheck symbols before editing; this map describes the inspected implementation, not a fixed API contract.

## Entry points and layers

Let `Overlay` mean `Assets/Toolkit/ManagerGeneratedContent/MicroGamesConfigurationOverlay` and `Content` mean `Assets/Toolkit/ManagerGeneratedContent`.

| Source | Responsibility |
| --- | --- |
| `Overlay/MicroGamesConfigurationOverlay.unity` | Runtime scene with the controller and `UIDocument`; verify script and UI asset references via `.meta` GUIDs. |
| `Overlay/Scripts/ConfigurationEditorController.cs` | Zenject dependencies, load/save, authoritative edit caches, model changes, navigation, and organisation theme updates. |
| `Overlay/Scripts/ConfigurationEditorView.cs` | Element queries, dynamic controls, UI events, tabs, inline language fields, pool tables, asset previews, modals, loading/saving feedback, and theme application. |
| `Overlay/UI/ConfigurationEditor.uxml` and `.uss` | Static UI shell and styling; substantial table and round UI is constructed in C#. |
| `Overlay/Scripts/PoolCsvImportValidator.cs` | Structural and asset-reference validation before imported pool rows replace the cache. |
| `Content/MicroGameConfigurationManager.cs` | Configured FullSerializer setup, runtime package isolation, apply, and recursive MIX serialization swaps. |
| `Content/MicroGameLocalisationManager.cs` | Localisation CSV import/export, including export of the editor DTO. |
| `Content/MicroGameExpansionManager.cs` | Expansion application/export and direct `SetContentFromPoolData` persistence. |
| `Content/MicroGameSpriteManager.cs` | Image handling and filling missing template images. |
| `Content/MicroGameContent.cs` | Typed content cache, image bytes, and metadata. |
| `Assets/Toolkit/Global/Installers/MissionSettingBase.cs` | Template/runtime package selection and serialization swap/restore. |
| `Content/FireBaseCloudStorage.cs` | Upload boundary; calls `UploadPreflight.Prepare` before replacement. |
| `Content/MicroGamesContextConfigurationOverlay/Scripts/OverlayController.cs` | Context selection and scene handoff into configuration editing. |

`Installer.cs` in the configuration overlay binds the scene loader; inspect the caller's scene-load bindings and `MonoConstructor` for the content dependencies. Do not assume that installer constructs the whole editing session.

## UI lifecycle and data ownership

`Start` gets `UIDocument.rootVisualElement`, creates the view, wires events, registers colour listeners, and starts `LoadContentAsync`. The editor exposes Mission, Rounds, Pool, Localisation, and Assets tabs. Mission/localisation values are displayed with languages inline; the pool has its own selected language. Leftover global-language members do not prove a visible global selector exists.

Loading downloads through `ICloudContent.DownloadAllToCacheAsync`, processes metadata against `TemplateMissionPackage.AllRounds`, and applies downloaded configuration. Missing background and expansion images are seeded from template content while preserving configured images. Downloaded expansion data is applied; template pool fallback fills missing data/references without replacing configured non-empty values. Localisation comes from downloaded CSV or a template/runtime fallback DTO.

| Editable data | Authority during the session | Save path |
| --- | --- | --- |
| Mission, round, value-object settings | `missionSettingBase.MissionPackage` (runtime package when available) | `configManager.SetContent` |
| Localised text | Controller `localisationData` | `localisationManager.SetContent(content, localisationData)` |
| Random pool | `poolData[roundId][language]`, a `string[][]` CSV grid | `expansionManager.SetContentFromPoolData` when populated |
| Images | `microGameContent` cache and `deletedAssetKeys` | `CopyAllImages`, filtering deleted identities |

Preserve `EnsureRuntimePackageFromTemplate` and existing editability checks when adding mutations, especially when downloaded configuration is absent or a mechanic lacks an `Apply` implementation. Do not write to the template as session state.

## Save and identity invariants

`HandleSave` rejects `Original` context and overlapping saves. It builds fresh content, uploads through `ICloudContent.Upload`, and clears dirty/deletion state only after success. Errors leave an explicit save error UI. Closing dirty content prompts before returning to the context overlay.

`BuildMicroGameContentAsync` serializes configuration and the localisation DTO. When pool rows exist, it writes the cached source-format CSV directly. Only its fallback uses expansion reimport/export. Do not replace the direct path with unconditional expansion export: that can turn edited text back into internal localisation keys.

Configuration serialization temporarily swaps in runtime packages, including nested MIX mission settings, and restores in reverse order in `finally`. Keep that restoration and the configured serializer rather than serializing template fields directly.

Images are copied from the current cache, preserving downloaded and newly uploaded/replaced bytes. The builder also carries supported TakeAway and RAG content through. Re-exporting all images from Unity template sprites would overwrite configured assets.

`GetAssetKey` combines content type, round ID, round number, sub-MIX microgame identifier, and filename. A filename alone is not a deletion identity. Preserve these metadata fields when duplicating or replacing assets; verify per-round references after a save/reload.

Nested value objects are enumerated recursively with GUID deduplication. `HandleValueObjectChanged` targets the persistent ID and changes `IsMarkedAsDeleted`; propagation across rounds is limited to other representations of the same ID. Avoid toggling a parent based on a nested row's display index.

## Pools and CSV

The controller selects renderers using `IExpansion.GetStructureType`: flat, flat-grouped, sectioned, and sectioned-grouped structures. It consumes `GetFlatStructureInfo`, `GetSectionedStructureInfo`, and `GetGroupedSectionedStructures` rather than one universal table schema. Inspect the actual mechanic expansion declaration when changing columns, asset fields, or row rules.

Use `CSVDataHelper` parsing and escaping. Group/section markers and blank separators are structural, not ordinary editable rows. Preserve the distinction between editor marker strings and persisted CSV structure.

`ApplyImportedPoolCsv` validates structure and asset references before mutation, then synchronizes other language grids through structure-aware helpers. Preserve translated fields while synchronizing shared structure; inspect those helpers before extending a schema. An invalid import should not partially replace existing rows.

LocateAndAnswer complex pools have migration/compatibility handling, active-question selection, eligible spot IDs, and a position canvas. Read those branches for a related change instead of generalizing them to every mechanic.

## UI and verification

For a UXML rename, follow `root.Q` lookups and callbacks in the view. For dynamic rows, inspect creation methods and rebuild behavior as well as the static UXML. Theme application happens after population so dynamic controls receive organisation colours, and listeners update it later. The view also applies C# styling; USS alone may not control the final appearance.

Choose tests according to the affected behavior:

- `Tests/Editor/ConfigurationEditorRegressionTests.cs` and `ConfigurationEditorFeedbackRegressionTests.cs`: editor behavior and feedback.
- `Tests/Editor/MixConfigurationSerializationRegressionTests.cs`: nested MIX persistence.
- `Tests/Editor/PoolStructureDeclarationRegressionTests.cs`: expansion declarations.
- `Tests/Editor/ProductionMicroGameCompatibilityTests.cs`: production mechanic compatibility.
- `Tests/Editor/UploadPreflightTests.cs`: upload validation.
- `Tests/Editor/UI/NestedValueObjectInteractionUITests.cs`: nested UI interactions.
- `Tests/PlayMode`: real-scene visual workflows and persistence; check assembly definitions and class declarations because similarly named files exist at multiple levels.

`Editor/ConfigurationTestSuiteRunner.cs` exposes **Tools > MicroGames Configuration > Run Full Test Suite**, which runs the EditMode group and writes `Library/TestResults/ConfigurationOverlay.xml`. The name does not include the separate PlayMode run.

`Editor/ConfigurationPlayModeTestSuiteRunner.cs` exposes **Tools > MicroGames Configuration > Run PlayMode Visual Workflow**, with **Run All** and narrower selections. Results go to `Library/TestResults/ConfigurationOverlay.PlayMode.xml`; visual artifacts are under `Artifacts/MicroGamesConfigurationOverlay`. Inspect the runner before invoking it: Run All cleans prior visual artifacts. Review screenshots for layout; successful assertions alone do not establish visual quality.

For a targeted change, use the relevant existing tests and add coverage only for meaningful changed behavior. Check save/reload with synthetic content or existing test doubles, including the relevant language, round, or MIX identity. Report exactly which tests and visual checks ran.

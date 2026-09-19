# Layout editor implementation guide

Paths are relative to the game-toolkit Unity checkout. This describes the inspected implementation; verify current symbols when making a change.

## Source map

Let `Overlay` mean `Assets/Toolkit/ManagerGeneratedContent/MicroGamesConfigurationOverlay`, `Content` mean `Assets/Toolkit/ManagerGeneratedContent`, and `Mechanics` mean `Assets/Toolkit/Mechanics`.

| Source | Responsibility |
| --- | --- |
| `Overlay/Scripts/RoundVisualEditor.cs` | Dynamic UI, canvas and inspector, pointer interaction, previews, layout validation/copy, and `LayoutHistory` |
| `Overlay/Scripts/RoundVisualEditorMappings.cs` | Supported round/object types, authored field allowlists, slot arrays, pool text ownership, asset/text mappings, and cache invalidation |
| `Overlay/Scripts/ConfigurationEditorController.cs` | Runtime isolation, round opening/reset, mutation callbacks, localisation and pool authority, cached asset lookup, dirty state, and history lifetime |
| `Overlay/Scripts/ConfigurationEditorView.cs` | `OnEditRoundLayout`/`OnResetRoundLayout`, round buttons, hiding/restoring the main editor, confirmation UI, and theme styling |
| `Overlay/UI/ConfigurationEditor.uss` | `.round-visual-editor`, `.visual-*`, compact toolbars, inspector scrolling, and canvas styling |
| `Overlay/UI/ConfigurationEditor.uxml` | Main editor shell; the layout controls are constructed in C#, not declared here |
| `Assets/Toolkit/Global/ValueObjects/BaseRound.cs` | Serialized `backgroundPosition` and `backgroundSize` |
| `Assets/Toolkit/Global/ValueObjects/RuntimeMissionPackageClone.cs` | Graph cloning and `IsolateRoundContents`, preserving persistent identities and internal references |
| `Content/MicroGameConfigurationManager.cs` | Runtime package creation, configured serialization, recursive MIX swaps, and apply |
| `Assets/Toolkit/Global/Installers/MissionSettingBase.cs` | Template/runtime package ownership and capability contract |
| `Mechanics/Mix/Scripts/MissionSettings.cs` | Recursive child capability and package behavior |
| `Assets/Toolkit/Background/Scripts/ViewControllers/BackgroundImage.cs` | Gameplay `ApplyLayout`, native sizing, and async background image sizing |
| `Overlay/Tests/Editor/RoundVisualEditorTests.cs` | Synthetic model, controller, serialization, UI interaction, and screenshot fixtures |
| `Overlay/Editor/ConfigurationTestSuiteRunner.cs` | Focused Round Layout and full configuration EditMode test runners |

Mechanic value objects and gameplay renderers live under `Mechanics/<Mechanic>/Scripts/ValueObjects` and `Scripts/ViewControllers`. Inspect the actual copy/apply implementation as well as serialization when adding a field.

## Session and persistence

The Rounds tab calls `AddRoundLayoutButton` for supported rounds when the mission supports runtime package generation. `OpenRoundLayout` creates an editable runtime package when necessary, detaches cross-round shared objects, loads artwork, and constructs `RoundVisualEditor` with callbacks. `SetRoundLayoutOpen` hides the normal editor while the overlay is open.

`ApplyVisualChange` finds representations by persistent ID within the selected round, validates the first write with `TrySetValue`, updates the other representations, and clears the mechanic cache. Slot and spawn callbacks use their own typed validators. These callbacks are used inside `LayoutHistory.Apply`, whose controller-supplied `changed` callback marks the editor dirty.

`GetLayoutHistory` keys histories by round object reference. Closing and reopening the same round retains history; loading content clears the history collection. Dragging previews a translation and commits on pointer-up. Escape, capture loss, or pointer cancellation clears the uncommitted drag. Colour slider gestures use `BeginGesture`/`EndGesture` to group changes; a new edit invalidates redo.

On close, dispose the visual overlay, release loaded value-object assets, restore the main editor, rebuild rounds/localisation, and apply the organisation theme. Preserve cleanup on failed asynchronous opening and controller destruction too.

Save remains the main controller's `HandleSave` -> `BuildMicroGameContentAsync` -> `ICloudContent.Upload` path. Configuration comes from the runtime package, localisation from the controller DTO, and pool CSV from the per-round/per-language cache. `MicroGameConfigurationManager.SetContent` and the configured serializer handle runtime/template swaps, including MIX children. Validate a fresh deserialize/apply, not only a serialized field or the still-open instance.

## Coordinates, identity, and validation

- `ReferenceSize` is `(1920, 1080)`. `ToCanvas(x, y)` yields `(960 + x, 540 - y)`; `FromCanvas` reverses it. For example, `(100, -70)` maps to `(1060, 610)`.
- `FitCanvas` scales the reference canvas to the viewport. PuzzleMotion expands the fitted extent to show offscreen spawn/destination points. Pointer deltas must be converted through `WorldToLocal`, not divided by an assumed fixed zoom.
- Rendering respects the source prefab's `RectTransform.pivot` where available. Backgrounds use centred positioning and numeric editing only, and remain behind selectable objects.
- `CollectItems` walks authored value-object arrays, recursively enters PuzzleChart micro-rounds, and deduplicates by `(source.Id, group)`. The stage picker shows round-level items plus the selected stage. Preserve a shared object's separate stage representations.
- Ordinary editable fields must be explicitly mapped, marked `[SerializeField]`, and not `[fsIgnore]`. `enabled` is a special mutation of `!IsMarkedAsDeleted`, unavailable for the background/round itself.
- `TrySetValue` checks exact field types, finite coordinates, magnitude limits, dimensions, enum membership, colours in `[0, 1]`, and font sizes. `Vector2Int` conversion happens before the final size checks; a small positive dimension can round to zero and become invalid.
- Zero size is a legacy/native sentinel for backgrounds, mapped images/targets, and `contentImageSize`. Do not replace it with measured preview dimensions just by opening the inspector. `AddVector` can display resolved dimensions while the stored field stays zero.

## Mechanic-specific behavior

| Mechanic | Editable layout and constraints |
| --- | --- |
| PuzzleChart | Images, text, targets, draggables, selectors, capacity meters, information/skip buttons, and nested `MicroRound` stages. Draggable `size` controls bounds; `contentImageSize`/`contentImageColor` control content artwork. Theme draggables do not expose content artwork overrides. Font fields depend on the draggable variant and override flag. |
| Dialog | Authored images and text. The layout editor does not author conversation graphs. Its mappings read authored arrays directly without an expansion cache clear. |
| LocateAndAnswer | Images, text, and spots. A spot's size is its hit area; spot artwork uses native dimensions. Zoomed text controls apply only to `ZoomedImageWithText`; `textPosition` is an offset in that prefab panel. Keep explicit answered-position enablement so `(0, 0)` can be an intentional override. |
| PopTheBubbles | Images/text and placement slots from the round's `overridePositions`. Empty overrides preview theme-generated positions. Bubble content is sampled into slots, not authored as fixed bubble-to-slot assignments. |
| WhackTheMole | Images/text, custom slots from `overidePositions` (the serialized spelling), and excluded coordinates in `takenPositions`. These are integer arrays. Generated positions use the existing gameplay helper and exclusions. |
| PuzzleMotion | Images, text, targets, obstacle bounds, agent spawn side/destination override, and round `spawnPositions` rules. Agents and spawn rules are not freely draggable positions. Obstacle artwork remains prefab-owned. |

For PopTheBubbles and WhackTheMole, `UsesGeneratedPositions` and `CollectSlots` must stay read-only. **Use custom positions** explicitly snapshots the generated slots into the round array; missing theme dimensions or no available slots leaves that action unavailable. Array field/index identifies a slot; do not invent value-object GUIDs. `TrySetSlot` clones the array before replacing an entry and preserves integer versus floating-point storage. `takenPositions` are exclusions, not slots to populate with content.

PuzzleMotion's `BuildSpawnInspector` edits a stored rule: side, along-edge offset, outside-screen distance, opposite destination, or an explicit destination. `TrySetSpawn` snapshots rules for independent edits/history. Start/destination previews use the gameplay `Round.GetStartPosition`/`GetDestination` helpers. Agent preview uses the first matching rule; an agent destination override of `(0, 0)` uses the rule destination. This is a static sample, not a pathfinding or randomized-assignment simulation.

Complex LocateAndAnswer expansions own spot and answered positions in pool CSV. Their template spot mappings deliberately omit those position fields. `RenderLocatePool` shows the selected question's markers and eligible spots read-only; **Edit pool positions / content** closes the overlay and passes round, language, and question to `OpenRoundPool`. For ordinary spots, legacy nonzero `overrideAnsweredPosition` also enables the answer override; disabling it must clear the coordinates through the existing setter.

## Localisation, pools, and artwork

`LayoutTextKey` uses an existing localisation key when present and otherwise resolves the source-ID prefix. `ChangeLayoutText` requires an editable owning runtime object, a known language, and text not owned by a pool. It records an `ApplyText` history entry and delegates the write to `HandleLocalisationValueChanged`. Do not mutate the value object's key to change its displayed text. Shared keys affect other consumers even though spatial edits are round-scoped.

`TextOwnedByPool` is authoritative even when a preview replacement is absent. With an expansion, draggables, agents, spots, bubbles, and moles are pool-owned; mapped text/targets also depend on section membership. Missing section data is treated conservatively. Enable content edits only after checking this helper, not merely whether `poolContent` has an entry.

The controller adapts the cached CSV through `PoolSections` and `PlacementPoolSections`. The view's `UpdatePool`, `UpdatePlacementPool`, and `UpdateLocatePool` select sample content into temporary dictionaries. Preserve those separate formats; a flat draggable sample, grouped placement content, and a LocateAndAnswer question are not interchangeable schemas.

`OpenRoundLayout` filters expansion images by round, deletion key, and MIX child compatibility. Lookup first tries the exact full path, then a filename match with current-language/neutral preference, accepting that fallback only when unique. Preserve this ambiguity handling and current uploaded bytes. Backgrounds resolve from the content cache by round; value-object asset loading supplies authored sprites/prefabs.

`ResolveSprite` and `ResolveTextDefaults` inspect prefab variant gates without instantiating gameplay behaviours. Theme previews generally use a primary sprite rather than full composite prefab geometry. For a parity bug, compare the actual gameplay renderer, including async image completion; a later native-size call can overwrite a valid authored size. PuzzleChart's `DraggableImage` and `DraggablePlacedImage` must both retain artwork sizing/tint when the object changes state.

## Copy and reset

`TryCopyLayout` requires the same supported mechanic type and compatible stage/object/field structure. It matches persistent IDs first, then type and authored slot order within each stage. It gathers writes and rejects incompatibility before applying them, including conflicting source values for an object shared across destination stages.

Copy snapshots placement/spawn arrays and background fields. Normal copy checks compatible array counts, accounting for generated placement counts; reset can restore template arrays with different counts. Copy/reset exclude content, image paths, answers, enabled flags, and identifiers. They are one-time copies, not links between rounds.

`RequestRoundLayoutReset` finds the template by round index plus ID, falling back only to a unique ID match. The existing modal confirms reset before runtime isolation and a history-wrapped copy with `reset: true`. Preserve that guard and validate the owning child for MIX rounds.

## Validation entry points

Run focused cases from `Overlay/Tests/Editor/RoundVisualEditorTests.cs` according to the change:

| Concern | Existing cases to locate |
| --- | --- |
| Ownership and persistence | `SharedRoundLayout_IsIndependentAfterSaveAndApply_WithExistingFieldsAndIds`, `LayoutEdit_SerializesThroughConfigurationManager_AndPreservesTemplate`, `NestedObjects_UsePersistentIdentityAndKeepStagesSeparate` |
| Copy/reset/history | `CopyLayout_IsOneTimeAndPreservesContent_RejectsIncompatibleRoundsBeforeWriting`, `ResetLayout_RequiresConfirmation_PreservesContent_AndCanBeUndoneAfterReopening`, `History_GroupsSliderChanges_TracksEnabledAndBackground_AndInvalidatesRedo` |
| Read-only and numeric guards | `LayoutValidation_RejectsInvalidSizesAndUnlistedFields`, `OriginalPreview_DisablesInspector_AndDisposesOverlay`, `LayoutEditing_MixWithUnsupportedChild_RemainsBlocked` |
| Text and pool ownership | `LayoutText_ControllerReopenAndSaveFreshLoad_PreserveSelectedLanguageAndGuards`, `InspectorAndPoolPreview_EditLayoutWithoutChangingPoolContent`, `LocateComplexPool_PreviewsSlotsWithoutWrites_AndOpensMatchingLanguageAndQuestion` |
| Placement and motion | Cases beginning `PlacementLayout_`, `PlacementArrays_`, `PlacementInspector_`, `MotionLayout_`, `WhackImage_`, and `MotionArtwork_` |
| Other mechanics and MIX | Cases beginning `DialogLayout_`, `LocateLayout_`, `MixPuzzleAndDialog_`, and `WaveOneInspector_` |
| Gameplay appearance | `BackgroundLayout_UsesNativeLegacyDefault_AndResetsBetweenRounds`, `DraggableArtworkOverride_PersistsAndIsAppliedByGameplay_WithNativeLegacyDefault` |

**Tools > MicroGames Configuration > Run Round Layout Tests** runs the selected EditMode groups, including layout, MIX serialization, and selected compatibility regressions. The runner writes `Library/TestResults/ConfigurationOverlay.xml`, the same result path used by its full suite; inspect the actual completed run. This is not the separate PlayMode suite.

UI fixtures write screenshots under `Temp/RoundVisualEditor`. For visual changes, inspect rendered output at the relevant viewport sizes and runtime panel, including inspector clipping, controls, stage/language selection, scaling, and the canvas area. Confirm import/Console errors too. Some fixtures use an `EditorWindow` as a test host; that does not change the feature's runtime architecture.

For behavioral changes, verify the relevant edit -> close/reopen -> save/build -> fresh apply path with synthetic data, retaining templates and unrelated round/content values. Add coverage when behavior changes need it; do not claim static source checks or skill validation ran Unity tests.

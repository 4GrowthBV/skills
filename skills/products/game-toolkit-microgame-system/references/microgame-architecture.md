# Microgame architecture reference

Use this reference as a stable navigation map. Verify implementation details in the current checkout before reporting or modifying them.

## End-to-end flow

```text
host or test launcher
  -> GamificationPlayerManager receives or constructs MicroGamePayload
  -> GamificationPlayerController waits for shared asset initialization
  -> identifier routing
  -> MicroGameLoader loads mission settings + theme + cloud content
  -> StartMicroGameMono creates the runtime mission package
  -> FadeInOut loads the mechanic scene and injects runtime objects
  -> shared installer + mechanic installer compose gameplay
  -> MissionController runs intro/countdown and starts RoundManager
  -> mechanic controller completes or fails rounds
  -> MicroGameController submits takeaways and result
  -> debrief/exit returns to the Gamification Player shell or host
```

## Launch contract

`MicroGamePayload` is defined in:

`Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/DataTransferObjects/ExternalEvents/JSONWebTokenPayload.cs`

Important payload groups are:

- `micro_game`: ID, display name, identifier, star thresholds, and `extra_data`;
- `player` and `organisation`: identity-independent runtime presentation and locale context;
- `session`, `battle`, and `module`: scoring and persistence context;
- `environment`: environment classification used by platform services;
- `integration`: return/integration context forwarded during result submission;
- `context_type`: `direct_play`, `module_session`, `battle_session`, `daily_challenge`, `public_micro_game`, or no recognized context.

Do not quote real serialized payloads from source, logs, assets, or live systems.

## Routing

The main listener is:

`Assets/Toolkit/GamificationPlayer/Scripts/GamificationPlayerController.cs`

`GamificationPlayerController` subscribes to `GamificationPlayerManager.OnMicroGameOpened`, waits for the initial Addressables catalog work, applies launch-level theme, badge, and speed choices, then selects a startup path.

Special identifier families use dedicated loaders for Social Game, Triviant, Onboarding, Chat, Story, and test modes. Ordinary mechanics are delegated to:

`Assets/Toolkit/GamificationPlayer/Scripts/MicroGameLoader.cs`

Current ordinary prefix mappings include:

| Prefix | Mission-settings type |
|---|---|
| `PUZ` | Puzzle Chart |
| `POP` | Pop the Bubble |
| `LOA` | Locate and Answer |
| `WM` | Whack the Mole |
| `PUM` | Puzzle Motion |
| `PAN` | Puzzle Animation |
| `BDG` | Bridge |
| `NAV` | Navigation |
| `MOA` | Move and Answer |
| `ENS` | Enter and Select |
| `DIA` | Dialog |
| `NOT` | Note Spotter |
| `MIX` | Mixed mechanic |
| `GTP` | Guess the Picture |

These are explicit string checks, not a registry. Verify the source before treating this table as exhaustive.

## Phase-one loading

For an ordinary microgame, `MicroGameLoader.LoadMicroGame<TMissionSettings>` starts three independent operations and continues only after all have completed:

1. the mission-settings Addressable at the microgame identifier;
2. the `ThemePackage` Addressable at the selected theme identifier;
3. contextual Firebase-managed content downloaded to a `FirebaseContentCache`.

Primary sources:

- `Assets/Toolkit/GamificationPlayer/Scripts/LoadAssetAsyncMono.cs`
- `Assets/Toolkit/GamificationPlayer/Scripts/LoadThemePackageAsyncMono.cs`
- `Assets/Toolkit/GamificationPlayer/Scripts/LoadFirebaseAssetAsyncMono.cs`
- `Assets/Toolkit/GamificationPlayer/Scripts/MicroGameLoadingStatus.cs`

The loaders survive scene changes long enough to finish, expose progress through `IMicroGameLoadingState`, and release valid Addressables handles when destroyed.

## Runtime content assembly

`Assets/Toolkit/GamificationPlayer/Scripts/StartMicroGameMono.cs` performs the bridge from loaded configuration to gameplay:

1. require a packed mission-settings asset;
2. attach the current payload to the mission settings;
3. create an isolated runtime package from the authored template;
4. apply downloaded configuration, localization, expansions, takeaways, and images when valid content exists;
5. select a seed based on battle, daily, module, explicit random mode, or a new GUID;
6. prepare the microgame localization provider and select a supported player locale;
7. notify the screen manager and start the mechanic transition.

The content application boundary is implemented by:

`Assets/Toolkit/ManagerGeneratedContent/ManagerGeneratedContentController.cs`

Cloud content applies only to a template mission and should target the runtime package, leaving the authored template available for later sessions.

## Scene and dependency composition

`Assets/Toolkit/GamificationPlayer/Scripts/LearnStrikeKickoff/FadeInOut.cs` loads the scene named by `MissionSettingBase.TypeOfMechanic` through `AddressableZenjectSceneLoader`. Before activation it injects and binds:

- the concrete `MissionSettingBase` instance;
- the loaded `ThemePackage`;
- the `ManagerGeneratedContentController`;
- an optional `StoryModeController`;
- the session-level `MicroGameController`.

The loaded mechanic scene then composes two layers.

### Shared layer

`Assets/Toolkit/Global/Installers/Installer.cs` binds common behavior such as:

- `MissionController`;
- `RoundManager` and round factory;
- game state;
- background, introduction, foreground, and debriefing controllers;
- theme scene loading;
- countdown and shared presentation services.

### Mechanic layer

Each folder under `Assets/Toolkit/Mechanics` normally contains a feature installer plus a `Controller` or `GameController`. The installer resolves the concrete mission-settings type, reads mechanic-specific prefab settings from the theme, and binds mechanic state collections, factories, sequences, and input behavior.

Use `Assets/Toolkit/Mechanics/PuzzleChart/Scripts/Installer.cs` as a representative example, not as a universal implementation contract.

## Mission lifecycle and sprite pipeline

`Assets/Toolkit/Global/MissionController.cs` owns the shared transition into gameplay:

1. begin loading the first round's lazy assets during initialization;
2. load the shared theme scenes;
3. show the introduction;
4. run the countdown after the player starts;
5. await first-round readiness after the countdown;
6. retry a failed first-round load up to three times;
7. enter the game state and call `RoundManager.StartNextRound`;
8. stop with score zero and return to the shell if all retries fail.

All mechanic controllers are expected to keep a rolling asset window:

- current round loaded;
- next round preloading;
- previous round released after transition.

This avoids holding every round's sprite bundle in memory. Details and the current implementation status are documented in:

`Documentation/split-loading-architecture.md`

New lazy sprites must be processed by the repository's `Tools/4Growth/Migrate Sprites to LazySprite` editor workflow so Addressables ownership and inherited offline labels remain correct.

## Round state, scoring, and completion

`Assets/Toolkit/Global/RoundManager.cs` creates runtime rounds from mission content, enforces at most one active round, emits start/pause/end events, and calculates the result:

- ordinary score: remaining-time score summed across scoring rounds;
- fixed-score missions: mission maximum score;
- win state: all scoring rounds satisfy completion rules;
- battle and public contexts can mark rounds as always-win according to current mission rules.

The selected mechanic controller interprets player input and calls `CompleteActiveRound` or `FailActiveRound`. It also owns mechanic-specific feedback and next-round asset pipelining.

`Assets/Toolkit/GamificationPlayer/Scripts/MicroGameController.cs` listens for the last round to end. Outside Story Mode it may generate and upload a takeaway result, then calls `GamificationPlayerManager.StopMicroGame(score, hasWon)`. Context-specific notification behavior may follow a successful stop request.

`Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/GamificationPlayerManager.cs` submits app scores, moves the current payload to finished state for restart support, clears the active payload, and signals the host where applicable. Debrief and exit controls call `GamificationPlayerController.LoadGamificationPlayerHelper` to transition back to the shell.

## Editor and testing paths

- `Assets/Toolkit/GamificationPlayer/Scripts/OpenMicroGame.cs` constructs or accepts a mock payload for editor/development launches.
- Directly opening a mechanic scene uses fallback mission settings and a fallback theme when runtime instances were not injected.
- `Assets/Toolkit/GamificationPlayer/Scripts/MicroGameTestRunner.cs` supports identifier-based test runs.
- Mechanic-specific tests and Unity Test Framework coverage should be preferred over scene presence as evidence of intended behavior.

## Troubleshooting by boundary

| Symptom | First boundary to inspect |
|---|---|
| Nothing launches | payload receipt, asset initialization wait, and identifier classification |
| Wrong mechanic | prefix routing and `TypeOfMechanic` on the loaded mission settings |
| Loading never completes | the three phase-one handles and their callbacks |
| Content is stale or missing | runtime package creation, content context, cache processing, and template flag |
| Wrong language | payload language, supported mission locales, localization initialization and table provider |
| Wrong or inconsistent randomization | context type, battle/module IDs, UTC daily seed, and `random_type` |
| Intro appears but gameplay stalls | first-round `LoadAssetsAsync`, countdown readiness gate, and retry result |
| Missing image in a later round | lazy-sprite migration, Addressables labels, next-round preload, and handle lifetime |
| Round never ends | mechanic controller completion condition and `RoundManager` state |
| Score is not reported | last-round event, takeaway callback, active payload state, and app-scores request |
| Game finishes but host does not resume | debrief/exit action, return transition, and platform-specific host signal |

## Adding a new ordinary mechanic

Confirm the exact neighboring pattern in the current checkout, then normally provide:

1. a new `TypeOfMechanic` value and an Addressable mechanic scene;
2. a `MissionSettingBase` subtype plus serializable mission/round content;
3. a mechanic installer derived from `BaseInstaller`;
4. mechanic controllers, state collections, sequences, and prefab factories;
5. theme prefab settings and references;
6. a distinct identifier prefix and `MicroGameLoader` branch if the existing mappings do not cover it;
7. packaged/template content, localization, and Addressables ownership labels;
8. completion calls into `RoundManager` and rolling lazy-asset behavior;
9. focused tests and an editor launch configuration.

Avoid copying an entire mechanic when shared global infrastructure already supplies the needed lifecycle behavior.

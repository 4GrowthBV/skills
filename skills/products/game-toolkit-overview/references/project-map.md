# 4growth game-toolkit project map

Use this reference as the stable mental model for the repository. Verify changeable facts from the live project files before presenting them.

## Purpose

`game-toolkit` is a Unity product platform used to assemble branded gamified learning applications. It combines reusable microgame mechanics, product shells, backend integration, content delivery, social and story experiences, and a hybrid scripted/AI chat system.

The repository may currently be configured for a particular product such as LearnStrike, while also containing code and assets used by other 4growth deployments. Never describe the current `productName` as the complete scope of the repository.

## Architecture at a glance

| Layer | Primary responsibility | Main locations |
|---|---|---|
| Product shell | Startup, navigation, platform handling, product composition | `Assets/Toolkit/GamificationPlayer`, active scenes in `ProjectSettings/EditorBuildSettings.asset` |
| Shared Unity runtime | Dependency injection, localization, themes, notifications, analytics, offline behavior, common UI and loading | `Assets/Toolkit`, especially `Zenject`, `Global`, `Localisation`, `Theme`, and `Foreground` |
| Experiences | Microgame mechanics, stories, social games, Triviant, takeaways, onboarding and chat launches | `Assets/Toolkit/Mechanics`, `StoryMode`, `SocialGame`, `SocialFramework`, `Triviant`, `TakeAways` |
| Gamification Player client | API endpoints, DTOs, sessions, events, chat orchestration and local RAG | `Packages/com.4growth.gamification-player-app-for-unity` |
| Embedded web UI | MultiChat and onboarding HTML/CSS/JavaScript rendered through the Unity/webview bridge | `Assets/StreamingAssets/MultiChatBoilerplate`, `Assets/MultiChatBoilerplate`, `Assets/OnboardingBoilerplate` |
| Unity backend | Protected GP API proxy, AI streaming and tools, authentication, notifications and version checks | `GameToolkitCloudCodeModule` |
| Firebase support | CCD download proxy and controlled Firebase Storage file operations | `CloudCode/CCDProxy` |
| Content and configuration | Mission settings, Addressables, cloud-delivered assets, localization and generated configuration | `Assets/Toolkit/MissionSettings`, `Assets/AddressableAssetsData`, `Assets/Toolkit/CloudContentDelivery`, `Assets/StreamingAssets` |

## Main runtime flow

1. Unity starts one of the scenes enabled in `ProjectSettings/EditorBuildSettings.asset`.
2. `Assets/Toolkit/Zenject/GameInstaller.cs` registers application-wide services such as authentication, localization, Addressables support, platform notifications, offline synchronization, RAG, screen handling, Firebase access, and bridge components.
3. The Gamification Player shell receives platform or embedded-app context. `GamificationPlayerManager` publishes application events and exposes client functionality.
4. `Assets/Toolkit/GamificationPlayer/Scripts/Installer.cs` registers factories that load microgames, stories, social games, Triviant, onboarding, and MultiChat.
5. Content is selected from a `MicroGamePayload` or related configuration and loaded through scenes, Addressables, Firebase, or other configured content sources.
6. The selected experience runs on shared toolkit components and reports its session or result through the Gamification Player client.
7. Protected server operations go through Unity Gaming Services Cloud Code rather than exposing service credentials in the client.

Compact flow:

`host/native app -> Unity authentication -> Gamification Player shell -> content loader -> experience -> Cloud Code -> GP API / OpenAI / Firebase`

## Key client systems

### Dependency injection and composition

The project uses Extenject/Zenject. `GameInstaller` owns global bindings; feature-level installers own local bindings. When tracing behavior, start with the active scene, find its installers, and follow the registered controllers or factories.

Important entry points:

- `Assets/Toolkit/Zenject/GameInstaller.cs`
- `Assets/Toolkit/GamificationPlayer/Scripts/Installer.cs`
- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/GamificationPlayerManager.cs`

### Game mechanics

Reusable mechanics live in `Assets/Toolkit/Mechanics`. Examples include Puzzle Chart, Guess the Picture, Navigation, Bridge, Move and Answer, Dialog, Note Spotter, Locate and Answer, Puzzle Animation, Puzzle Motion, Enter and Select, Pop the Bubble, and Whack the Mole.

Mechanics commonly contain runtime scripts, installers, editor tooling, scenes or prefabs, and configuration/value objects. Content instances are often driven by MissionSettings and Addressables rather than separate bespoke application code.

### Gamification Player package

`Packages/com.4growth.gamification-player-app-for-unity` is a reusable embedded Unity package. Its main areas are:

- `Scripts/Runtime/Endpoints`: API calls
- `Scripts/Runtime/DataTransferObjects`: request and response models
- `Scripts/Runtime/Session`: authentication and session state
- `Scripts/Runtime/Chat`: chat orchestration and collaborators
- `Scripts/Runtime/ThirdPartyAssets`: package-side integrations
- `Scripts/Tests`: EditMode, PlayMode, and support code

Use the package's own `package.json` and assembly definitions to verify its current version, supported platforms, and dependencies.

## Chat and AI flow

The chat subsystem supports scripted button flows and free-form AI conversation in the same persistent conversation.

1. The embedded chat UI sends user actions through the Vuplex/Unity bridge.
2. `ChatManager` manages initialization, history, daily scripted messages, activities, profiles, and UI-facing events.
3. `RAGService` retrieves relevant knowledge locally using the packaged embedding model and Unity Inference Engine.
4. `ChatAIService` constructs requests and subscribes to streamed Cloud Code messages.
5. The Cloud Code module calls the configured LLM provider, handles tool calls, and emits ordered delta, completion, cancellation, or error messages.
6. Tool markers in stored flat messages can be reconstructed into structured tool history. Environment-specific catalogs provide media cards, helplines, crisis content, and similar tools.
7. Conversation and profile data are persisted through the Gamification Player API.

Important sources:

- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/Chat/ChatManager.cs`
- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/Chat/Services/ChatAI/ChatAIService.cs`
- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/Chat/Services/RAG/RAGService.cs`
- `Assets/StreamingAssets/MultiChatBoilerplate`
- `GameToolkitCloudCodeModule/Project/GameToolkitCloudCodeModule.Chat.cs`
- `GameToolkitCloudCodeModule/Project/LLM`
- `Documentation/2 — Systeemarchitectuur.md`
- `Documentation/MultiChat-Features-Overview.md`

## Backend boundaries

### Unity Cloud Code module

`GameToolkitCloudCodeModule` is a C# module composed from partial classes. Inspect attributes named `CloudCodeFunction` for the deployed public surface.

Its responsibilities include:

- GP API GET, POST, PATCH, PUT, DELETE, and ZIP proxy operations
- route allowlisting and player/token ownership checks
- AI completion, streaming, tool execution, cancellation, and diagnostics
- media, helpline, crisis, notification, and version catalogs
- Firebase token handling and FCM registration
- battle and scheduled notifications
- client-version compatibility checks

Primary sources are `GameToolkitCloudCodeModule/Project/GameToolkitCloudCodeModule*.cs`, `Security`, `LLM`, `Catalogs`, and `DTOs`.

### Firebase functions

`CloudCode/CCDProxy/functions/src/index.ts` contains HTTP functions for:

- proxying approved Unity CCD download hosts, primarily for WebGL/iOS iframe behavior;
- listing, reading, and updating selected Firebase Storage files;
- validating allowed file types and preserving restrictions on structured content.

Verify scripts, Node runtime, and dependencies in `CloudCode/CCDProxy/functions/package.json`.

## Security model

Security-sensitive calls are intended to terminate in backend code:

- service credentials stay in Cloud Code or Firebase;
- the GP API proxy uses an explicit route allowlist;
- selected routes require player identity or a user token;
- the CCD proxy only accepts HTTPS URLs for approved host suffixes;
- upload endpoints limit file types and validate content structure.

When answering a security-specific question, inspect the current implementation in `GameToolkitCloudCodeModule/Project/Security` and the Firebase function rather than relying only on architecture documentation.

## Development and testing

The repository uses several test surfaces:

- Unity Test Framework EditMode and PlayMode tests in the Gamification Player package;
- experience-specific tests, including MultiChat tests under `Assets/MultiChatBoilerplate/Tests`;
- .NET tests under `GameToolkitCloudCodeModule/Tests`;
- TypeScript compilation and Firebase emulator scripts in the CCD proxy package.

Relevant configuration:

- Unity editor version: `ProjectSettings/ProjectVersion.txt`
- Unity package dependencies: `Packages/manifest.json`
- active build scenes: `ProjectSettings/EditorBuildSettings.asset`
- Cloud Code solution: `GameToolkitCloudCodeModule/GameToolkitCloudCodeModule.sln`
- Firebase scripts: `CloudCode/CCDProxy/functions/package.json`
- mobile post-build automation: `PostCloudBuildScripts`
- Unity build/editor utilities: `Assets/Toolkit/DevOpsTools`

Do not claim that tests pass unless they were actually run in the current checkout.

## Where to start for common questions

| Question | Start here |
|---|---|
| What launches in the current build? | `ProjectSettings/EditorBuildSettings.asset` and those scenes |
| Which global service creates this object? | `Assets/Toolkit/Zenject/GameInstaller.cs`, then feature installers |
| How is an experience selected and started? | Gamification Player `Installer`, controller, loaders, and factories |
| How does a microgame work? | Its folder under `Assets/Toolkit/Mechanics` and its installer |
| Where is backend API behavior defined? | Gamification Player `Endpoints`, then the Cloud Code proxy |
| How does chat work? | `ChatManager`, `ChatAIService`, `RAGService`, embedded web UI, then Cloud Code chat |
| Where is deployable AI tool content defined? | `GameToolkitCloudCodeModule/Project/Catalogs` |
| How is content delivered? | MissionSettings, Addressables, CloudContentDelivery, Firebase loaders |
| What controls platform differences? | preprocessor branches in installers/authenticators plus project settings |
| How is the app versioned or built? | `ProjectSettings`, `DevOpsTools`, Cloud Code project, post-build scripts |

## Interpretation cautions

- The repository contains many scenes because content, templates, third-party demos, and cloud-delivered scenes coexist. The build scene list is the authority for direct startup.
- Documentation is especially detailed for Herstel Buddy and MultiChat; it is not a complete inventory of every toolkit subsystem.
- Files under third-party/plugin/demo directories may dominate raw file counts. Exclude them when describing 4growth-owned architecture.
- Environment and customer variants are common. Confirm the selected environment and active configuration before explaining production behavior.
- Unity YAML assets and Addressables references can establish runtime wiring that is not visible from C# alone.

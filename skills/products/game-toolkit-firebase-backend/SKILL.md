---
name: game-toolkit-firebase-backend
description: Explains how the 4growth game-toolkit uses Google Firebase across Unity, Unity Cloud Code, Firebase Functions, Storage, and FCM. Use for authentication brokering, content/file flows, CCD proxying, push notification delivery, or Firebase-to-frontend tracing while keeping configuration and customer data private.
---

# Game Toolkit Firebase Backend

Explain Firebase as several separate integration paths rather than one backend. Treat every answer as public documentation.

## Subsystems

Distinguish these paths when present in the current checkout:

- **Storage/content:** Unity loads or manages content through the Firebase SDK or Firebase Storage REST APIs.
- **Authentication broker:** Unity Cloud Code obtains or refreshes a scoped Firebase token using server-managed credentials and protected player storage; authorized Unity tooling uses the returned short-lived token.
- **Firebase Functions proxy:** HTTPS functions proxy approved downloads or perform constrained Storage operations with input and content validation.
- **Push notifications:** the native Unity client receives an FCM device token, registers it through authenticated Cloud Code, and the backend sends notification messages through FCM.

## Workflow

1. Locate the Unity project root containing `Assets`, `Packages`, `ProjectSettings`, `GameToolkitCloudCodeModule`, and `CloudCode/CCDProxy`.
2. Identify which Firebase path the question concerns; do not blend Storage, Functions, authentication, and FCM.
3. Trace the Unity caller from `Assets/Toolkit/ManagerGeneratedContent` or `Assets/Toolkit/GamificationPlayer/Scripts/Notifications`.
4. For token and notification behavior, inspect the matching Cloud Code partial class and its Cloud Save or Secret Manager boundary.
5. For HTTP Functions, inspect `CloudCode/CCDProxy/functions/src/index.ts` and verify build/runtime dependencies in its `package.json`.
6. Trace the result back to the Unity callback, cache, loader, notification handler, or UI consumer.
7. Verify platform conditionals before generalizing behavior across WebGL, Android, iOS, and editor builds.
8. Prefer authored source and tests over documentation or bundled third-party Firebase SDK files.

## Primary sources

- `Assets/Toolkit/ManagerGeneratedContent/FirebaseTokenProvider.cs`
- `Assets/Toolkit/ManagerGeneratedContent/FirebaseCloudAPI.cs`
- `Assets/Toolkit/ManagerGeneratedContent/FirebaseCloudSDK.cs`
- `Assets/Toolkit/ManagerGeneratedContent/FirebaseCloudFactory.cs`
- `Assets/Toolkit/GamificationPlayer/Scripts/Notifications/FcmCloudRegistration.cs`
- `Assets/Toolkit/GamificationPlayer/Scripts/Notifications/NotificationService.cs`
- `GameToolkitCloudCodeModule/Project/GameToolkitCloudCodeModule.Auth.cs`
- `GameToolkitCloudCodeModule/Project/GameToolkitCloudCodeModule.Notifications.cs`
- `GameToolkitCloudCodeModule/Project/Firebase`
- `CloudCode/CCDProxy/functions/src/index.ts`
- `CloudCode/CCDProxy/functions/package.json`

Avoid treating bundled files under `Assets/Firebase`, generated platform libraries, or example assets as 4growth-authored architecture.

## Public-safe boundary

- Never reproduce Firebase configuration files, service-account material, API keys, tokens, project IDs, app IDs, sender IDs, bucket names, database names, internal URLs, allowed host suffixes, or authorization headers.
- Do not open or quote `google-services` files, platform property lists, local environment files, deployment configuration, generated resource assets, or customer-specific Firebase settings unless the task strictly requires inspection; even then, never include their values in the answer.
- Do not list stored object names, content paths, user/player identifiers, device tokens, Cloud Save values, notification recipients, or notification bodies.
- Describe validation structurally—HTTPS enforcement, host allowlisting, file-type limits, content-shape checks, role checks, token ownership—without publishing operational allowlists or customer data.
- Use placeholders such as `<firebase-project>`, `<storage-object>`, `<device-token>` and `<authenticated-player>`.
- If logs or errors contain data, summarize the failure category and redact the original text.

## Response guidance

- Answer in the user's language.
- Begin by naming the relevant Firebase subsystem and show its short end-to-end flow.
- Clearly distinguish direct client-to-Firebase traffic from calls brokered or guarded by Unity Cloud Code or Firebase Functions.
- Explain which component owns authentication and validation without exposing how to access a live environment.
- Mention repository-relative source files, not concrete configuration values.
- Separate repository evidence from assumptions about deployed Firebase rules or infrastructure.
- State that builds, emulators, or tests pass only when they were actually run.

## Boundaries

- Use the Unity Cloud backend subsystem for the generic Cloud Code API proxy.
- Use the AI chat-streaming subsystem for Cloud Code player-message streaming.
- Do not query Firebase, deploy functions, send notifications, read live Storage, or alter backend state unless explicitly requested and authorized.

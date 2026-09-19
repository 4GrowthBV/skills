---
name: game-toolkit-unity-cloud-backend
description: Explains how the 4growth game-toolkit Unity client communicates with the Unity Cloud Code backend and downstream APIs. Use for request/response flows, Cloud Code entry points, authentication boundaries, proxy behavior, DTO handling, or backend-to-frontend tracing. Use the dedicated chat-streaming or Firebase skill for those subsystems.
---

# Game Toolkit Unity Cloud Backend

Explain the current Unity client-to-backend architecture from repository evidence. Treat every answer as public documentation.

## Scope

Cover the generic Unity Cloud Code path:

`Unity UI or gameplay -> client manager/endpoint -> UGS authentication -> Cloud Code function -> guarded downstream service -> serialized response -> DTO/callback/event -> Unity UI`

The Cloud Code module is a backend-for-frontend and security boundary. Do not describe it as the primary data store. Separate synchronous request/response calls from asynchronous push mechanisms.

## Workflow

1. Locate the Unity project root containing `Assets`, `Packages`, `ProjectSettings`, and `GameToolkitCloudCodeModule`.
2. Find the relevant frontend caller under `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime` or `Assets/Toolkit`.
3. Trace the call through `GamificationPlayerEndpoints` or generated Cloud Code bindings to a method marked `[CloudCodeFunction]`.
4. Inspect the matching partial class in `GameToolkitCloudCodeModule/Project` and any guard in `Project/Security`.
5. Trace the returned value into its DTO, callback, manager event, and UI consumer. Do not stop at the network call.
6. Check whether the current code permits a narrowly allowlisted direct client request for the route; distinguish that exception from the normal Cloud Code proxy path.
7. Prefer source code and tests over descriptive documentation when they disagree.

## Primary sources

- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/Endpoints/GamificationPlayerEndpoints.cs`
- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/Endpoints`
- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/DataTransferObjects`
- `GameToolkitCloudCodeModule/Project/GameToolkitCloudCodeModule*.cs`
- `GameToolkitCloudCodeModule/Project/Security`
- `GameToolkitCloudCodeModule/Project/ModuleConfig.cs`
- `GameToolkitCloudCodeModule/Tests`

Treat generated bindings as transport glue; the authored client and Cloud Code implementations are authoritative for behavior.

## Public-safe boundary

- Never reproduce secrets, tokens, credentials, private keys, connection strings, internal hostnames, complete service URLs, or raw authorization headers.
- Do not enumerate full route allowlists, customer-specific identifiers, environment catalogs, deployment configuration, user identifiers, or stored payloads.
- Do not quote raw request or response bodies, logs, exception bodies, Cloud Save values, or configuration assets.
- Describe secret usage only as “a server-managed credential” and use neutral placeholders such as `<service>`, `<route>`, `<user>` and `<correlation-id>`.
- Mention validation categories—authentication, route allowlisting, ownership, role checks—without publishing operational values or rules that are unrelated to the question.
- If a source mixes architecture with sensitive values, report only the architecture and cite the file path.

## Response guidance

- Answer in the user's language.
- Start with a compact end-to-end flow, then explain only the relevant boundary and return path.
- Clearly label facts verified in the current checkout and avoid claiming deployment state from source alone.
- Name concrete classes and repository-relative files, but keep examples synthetic and payload-free.
- State that tests pass only when they were run in the current checkout.

## Boundaries

- For AI delta streaming, use the chat-streaming subsystem rather than generalizing from ordinary RPC calls.
- For Firebase Authentication, Storage, Functions, or FCM, use the Firebase subsystem.
- Do not browse live services, inspect deployed configuration, or mutate backend state unless the user explicitly requests it.

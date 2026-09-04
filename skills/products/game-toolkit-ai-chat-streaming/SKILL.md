---
name: game-toolkit-ai-chat-streaming
description: Explains the public-safe AI chat streaming flow in the 4growth game-toolkit, from the Unity UI through Cloud Code and back through ordered player push messages. Use for stream lifecycle, correlation, chunk ordering, cancellation, errors, UI updates, or chat transport troubleshooting without exposing prompts or user content.
---

# Game Toolkit AI Chat Streaming

Explain the transport and lifecycle of AI chat without disclosing conversation content, prompts, tool data, customer catalogs, or deployment details. Treat every answer as public documentation.

## Core flow

Trace this sequence in the current code:

`Unity chat UI -> ChatManager -> ChatAIService -> Cloud Code start RPC -> background LLM stream -> player push events -> ChatAIService reorder/correlation -> ChatManager events -> UI stream coordinator/typewriter`

The start RPC and the streamed response are separate channels: the RPC acknowledges acceptance, while response chunks and terminal state arrive asynchronously through the authenticated player's Cloud Code message subscription.

## Workflow

1. Locate the Unity project root containing `Assets`, `Packages`, `ProjectSettings`, and `GameToolkitCloudCodeModule`.
2. Start at the active UI controller and `ChatManager`; trace the exact call into `ChatAIService`.
3. Inspect subscription creation, request construction, correlation state, timeout handling, reconnection, and main-thread dispatch in `ChatAIService`.
4. Inspect `StartChatStream` and the background stream loop in `GameToolkitCloudCodeModule.Chat.cs`.
5. Inspect `ChatPushMessageComposer` and the payload chunker for event names, sequence numbering, size handling, and terminal messages.
6. Follow chunk and completion callbacks back through `ChatManager` into the UI controller and stream coordinator.
7. Check the current installer and scene wiring before claiming that the chat UI uses HTML/Vuplex. The current implementation may use Unity UI Toolkit while older documentation or retained assets describe an iframe-based frontend.
8. Use tests under the Cloud Code module, Gamification Player package, and `Assets/MultiChatBoilerplate/Tests` to verify contracts when relevant.

## Primary sources

- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/Chat/ChatManager.cs`
- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/Chat/Services/ChatAI/ChatAIService.cs`
- `Packages/com.4growth.gamification-player-app-for-unity/Scripts/Runtime/Chat/Interfaces`
- `Assets/MultiChatBoilerplate/Integration/MultiChatUIController.cs`
- `Assets/MultiChatBoilerplate/Scripts/ChatStreamCoordinator.cs`
- `Assets/MultiChatBoilerplate/Scripts/TypewriterEngine.cs`
- `GameToolkitCloudCodeModule/Project/GameToolkitCloudCodeModule.Chat.cs`
- `GameToolkitCloudCodeModule/Project/ChatPushMessageComposer.cs`
- `GameToolkitCloudCodeModule/Project/ChatPushPayloadChunker.cs`
- `GameToolkitCloudCodeModule/Project/LLM`

## Public-safe boundary

- Never reveal or paraphrase real system prompts, developer prompts, chat messages, profiles, RAG passages, embeddings, tool arguments, tool results, or stored conversation history.
- Do not enumerate customer- or environment-specific tools, media, helplines, crisis content, catalogs, model configuration, or routing instructions.
- Never expose secrets, tokens, player identifiers, correlation values, support codes, deployment identifiers, internal URLs, raw push payloads, or raw provider errors.
- Explain payloads only as schemas with neutral fields such as `<correlation-id>`, `<sequence>`, `<text-chunk>` and `<terminal-state>`.
- Use invented content such as “voorbeeldtekst” if an example is necessary. Do not reuse repository content as sample chat data.
- Report error categories and recovery behavior at a structural level; redact message bodies and identifiers.

## Response guidance

- Answer in the user's language.
- Lead with the two-channel design: start acknowledgement followed by asynchronous player messages.
- Explain correlation and sequence ordering because they are essential to correctness.
- Distinguish transport completion from persistence: final chat content is persisted through the separate data API flow.
- Mention cancellation, timeout, resubscription, and terminal events only to the depth needed by the question.
- Cite repository-relative files rather than copying implementation payloads.
- Do not claim that streaming is live or deployed merely because the source exists.

## Boundaries

- Use the general Unity Cloud backend subsystem for ordinary API request/response behavior.
- Use the Firebase subsystem for Firebase Authentication, Storage, Functions, or FCM notifications.
- Do not call an external LLM, inspect production conversations, or connect to deployed services unless explicitly requested and authorized.

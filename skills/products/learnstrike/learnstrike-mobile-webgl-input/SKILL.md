---
name: learnstrike-mobile-webgl-input
description: Diagnose, change, and validate mobile input for LearnStrike's MultiChatBoilerplate, especially when the Unity WebGL player is hosted in LearnWorlds browsers or app WebViews, while preserving LearnStrike's native iOS/Android behavior. Do not use for unrelated Unity input.
---

# LearnStrike MultiChat Mobile Input

LearnStrike is the product and can be built as WebGL or as native iOS/Android players. `MultiChatBoilerplate` is a product module whose WebGL build also runs inside the LearnWorlds app. The LearnWorlds app is a native container, but the embedded LearnStrike player remains WebGL and still uses the DOM/iframe keyboard bridge.

Use this skill when mobile typing, focus, scrolling, viewport sizing, compact chat layout, onboarding fields, or media-return behavior is involved in that module or its shared input infrastructure. Do not apply LearnWorlds-specific iframe behavior to every LearnStrike build target.

The target experience is chat-app-like: one tap opens the correct keyboard, the caret and selection work, text stays synchronized, the Unity canvas does not rescale, the conversation remains scrollable, and focus still works after navigation or a reconstructed WebGL runtime.

## Read the relevant references

- Read [references/architecture.md](references/architecture.md) before changing the keyboard bridge, WebGL template, LearnWorlds embed, or media lifecycle.
- Read [references/device-testing.md](references/device-testing.md) when reproducing or diagnosing behavior on Android or iOS.
- Read [references/learnworlds-app-webview.md](references/learnworlds-app-webview.md) when the host is the native LearnWorlds app or when interpreting USB/WebView evidence.
- Read [references/regression-checklist.md](references/regression-checklist.md) before declaring a fix complete or release-ready.
- Use the scripts linked from the device-testing reference for privacy-safe USB snapshots and debug-only in-page capability capture; do not improvise probes that collect input values or page URLs.

## Preserve these invariants

- Unity UI Toolkit owns product state, validation, layout, and the visible product design. The browser-created editable element is the IME, caret, selection, and text-entry surface; do not let it become an independent second input.
- Keep the Unity canvas and its backing buffer stable while the keyboard animates. Represent keyboard occlusion inside Unity layout instead of repeatedly resizing or recreating WebGL rendering resources.
- In nested LearnWorlds frames, use the highest same-origin accessible ancestor whose `visualViewport` demonstrably changes with the keyboard. Never assume it is `window.top`; a cross-origin boundary requires an explicit relay.
- Geometry is lifecycle state. Republish it after visibility, enablement, layout, tab, orientation, consumer, and WebGL-runtime transitions—not only at initial view creation.
- Focus must originate from a trusted user gesture. Preserve that activation through the Unity proxy creation/focus sequence.
- Scroll interception is limited to the reported scroll region. Pass through interactive controls, distinguish taps from drags, keep focus during a drag, and blur on an intentional conversation tap.
- Multiple consumers such as chat and onboarding use activation leases. Disposing one consumer must not disable the bridge for another; the surviving consumer must refresh its geometry.
- Treat iOS's Previous/Next/Done form assistant as native WebKit UI. HTML, CSS, input types, and `contenteditable` do not reliably remove it.
- Treat native bridge, deep-link, popup, fullscreen, and remote-inspection support as runtime capabilities to probe. The presence of a WebView bridge object does not prove that LearnWorlds registered a handler or exposed a navigation API.
- Validate the media-card round trip. Returning from media creates a fresh game iframe and must be treated as a new WebGL runtime, including new geometry and focus state.

## Workflow

1. Classify both dimensions of the environment: Unity player target (`WebGL` or native Android/iOS) and host (`standalone browser`, LearnWorlds browser harness, LearnWorlds native app WebView, or native LearnStrike app). Also record build/content version and whether the run is before or after media return.
2. Reproduce before editing. Capture tap count, focus/caret state, text synchronization, viewport/canvas measurements, scroll behavior, navigation state, and evidence of a renderer reload.
3. Identify the responsible layer using the responsibility map in the architecture reference. Do not compensate for a host-frame problem only inside UI Toolkit, or for stale Unity geometry only with broad browser hit areas.
4. Make the smallest source-of-truth change. An edited generated build is a fast experiment, not the lasting fix; mirror a proven experiment into the maintained template or host integration.
5. Add or update deterministic Unity tests where the behavior can be expressed without a real browser. Use real devices for IME, caret, viewport, iframe, WebView, memory, and animation behavior.
6. Run the regression checklist on Android and iOS. Include a media open/close cycle and keyboard focus after the reconstructed chat runtime.
7. Report observed evidence separately from inference. A visual page reload is not proof of an out-of-memory event unless logs or process/render-process evidence support it.

## Discover the current implementation

Do not assume file paths, class names, selectors, or message names from an earlier project revision. Inspect the current checkout and identify the owners of:

- the Unity-to-browser input contract and its platform guards;
- the browser-created editable proxy, focus, caret, canvas, and touch behavior;
- chat layout, interactive hit regions, compact mode, and quick replies;
- onboarding/profile field registration and input-mode configuration;
- the LearnWorlds host embed, viewport relay, and media lifecycle;
- automated tests for those behaviors.

Use targeted search terms such as `visualViewport`, `inputmode`, `postMessage`, WebGL JavaScript imports, keyboard state, quick replies, and onboarding input configuration. Confirm ownership from callers and runtime flow before editing; search hits are discovery evidence, not an API contract.

Configuration asset changes require the appropriate content update before remote testing. Maintained WebGL template changes require a player build for release, although a generated entry document can be patched temporarily to validate browser-only changes. LearnWorlds host-snippet changes can be tested without rebuilding Unity when deployment permits it.

## Platform and host boundary

The browser bridge is a WebGL implementation and should remain guarded by `UNITY_WEBGL && !UNITY_EDITOR`. This includes WebGL running inside the native LearnWorlds iOS/Android app: the host is native, but the LearnStrike content is not.

Native LearnStrike Android/iOS players do not use the DOM, `visualViewport`, or LearnWorlds iframe relay. They continue to use Unity's native field keyboard configuration; preserve the shared input-mode mapping and smoke-test native builds when shared UI/config code changes. Other WebGL modules and microgames should remain unaffected unless they explicitly activate and publish geometry to the bridge.

## Completion standard

A fix is not complete after one successful keyboard open. It is complete only when the relevant automated tests pass and the device matrix demonstrates stable repeated open/close behavior, correct caret/text/selection, scrolling, compact layout, media return, follow-up restoration, and first-tap keyboard focus after runtime reconstruction.

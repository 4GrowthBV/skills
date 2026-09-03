# LearnWorlds native app WebView

Use this reference only when LearnStrike WebGL content runs inside the native LearnWorlds app. Treat every observation about the host app as version-specific and recheck it after an app, operating-system, or WebView/WebKit update.

## Evidence boundary

Browser content can prove its own DOM, frame, viewport, storage, and exposed JavaScript APIs. USB tools can prove native process, input-method, memory, and inspection state. Neither source alone proves that LearnWorlds registered a particular native handler, intercepts a route, or implements popup/fullscreen callbacks.

Classify conclusions as:

- **verified for the tested build and device**;
- **supported by the underlying library or platform**;
- **inferred and awaiting a controlled device test**.

Do not turn a single device observation into a permanent host capability.

## Identify the runtime before diagnosing it

On Android, establish the foreground app, system WebView provider, input-method served view, app process, associated renderer process, and presence or absence of an app-owned DevTools socket. A Flutter or WebView class name is useful implementation evidence, but it is not a stable public LearnWorlds API.

On iOS, use Safari as an A/B control for the USB inspection path. Seeing Safari but not LearnWorlds shows that pairing and the proxy path work while the app content is not exposed through that path; it does not prove the exact native setting responsible.

Keep app and device identifiers out of shared reports unless they are essential to the diagnosis. Record versions at the level needed to reproduce a result, then remove customer, user, course, and device-specific data before publishing reusable guidance.

## Remote inspection

The package debug flag and WebView content debugging are separate concerns. Judge Android inspection by an app-owned DevTools target whose process and returned metadata agree; a generic Chrome target is not LearnWorlds evidence.

On iOS, WebKit inspection of app-owned views is controlled by native app configuration. Page HTML, CSS, Unity, and embed JavaScript cannot enable it. Keep the Safari control result with any conclusion drawn from a Windows proxy, and treat proxy compatibility as a separate variable.

When no target is available, combine the maintained in-page probe, passive USB snapshots, focused logs, and a screen recording. Do not claim console or DOM evidence that was unavailable.

## JavaScript bridge

Some LearnWorlds builds may use a WebView library that exposes a JavaScript bridge. Library support does not create a LearnWorlds API contract.

In the exact game frame:

1. observe the library's ready signal when one exists;
2. test whether the bridge object and callable surface exist;
3. invoke only handler names whose registration and argument contract are documented or directly observed;
4. never invent or brute-force handler names;
5. treat every useful handler as version-specific unless LearnWorlds documents it.

Bridge presence can differ between the top document and nested frames.

## Frames and viewport

A cross-origin game iframe cannot read the top document's `visualViewport`. Use the highest same-origin accessible ancestor that demonstrably reacts to the keyboard. If the useful viewport is beyond a cross-origin boundary, the owning ancestor must explicitly relay normalized geometry.

Measure rather than assume which layer resizes. Compare the host viewport, game-iframe rectangle, child layout viewport, visual viewport, canvas CSS bounds, and canvas backing size through the complete keyboard animation.

## Keyboard and form assistant

The browser-created editable proxy remains responsible for trusted focus, caret, selection, and IME connection while Unity owns product state and validation.

Native keyboard accessory UI is controlled by the host platform/WebView. HTML input types, `contenteditable`, autocomplete attributes, and CSS do not reliably remove it. Treat keyboard layout, action keys, accessory controls, and focus behavior as device-test results rather than cross-platform guarantees.

## Navigation, media, and fullscreen

- A working web route is not proof of a native deep-link contract.
- A bridge object is not proof of a registered navigation handler.
- `window.open()` may stay in the WebView, create a native child view, or open an external browser; verify receiving context, authentication, process lifetime, and return behavior.
- Current-frame navigation can preserve authentication while still discarding the originating WebView history; test both the app's Back control and the operating-system Back gesture/button.
- `requestFullscreen()` requires a trusted gesture, permission from every iframe ancestor, and host WebView fullscreen support. `document.fullscreenEnabled` alone does not prove that native app chrome will disappear.

For media cards, verify the entire round trip: release the game runtime, present media, create or restore the intended game runtime, restore conversation state exactly once, republish input geometry, and open the keyboard on the first post-return composer tap.

## Lifecycle and memory

Track the native host and WebView renderer separately where the platform exposes both. A stable host process does not prove that its renderer survived. A visual reload does not prove an out-of-memory event without process, memory, or log evidence.

Measure memory only during a short, deliberate sequence. Prefer stable rendering resources and one owner for iframe/runtime teardown; concurrent canvas reallocation, explicit graphics-context loss, and parent-owned frame removal can create avoidable instability.

## Maintained evidence stack

For keyboard or media-return diagnosis, capture:

1. **In-page state:** active-element metadata, viewport/frame geometry, canvas CSS/backing size, lifecycle, bridge presence, and a bounded event buffer.
2. **USB host state:** foreground match, host/renderer lifetime, input-method state, inspection target ownership, and narrowly filtered logs.
3. **Visual evidence:** exact taps, keyboard/caret behavior, canvas scale, media presentation, return path, and reload symptoms.

Use the maintained [capability-probe script](../scripts/learnworlds-webview-capability-probe.js) when DevTools is unavailable. It deliberately excludes input values, message payloads, URLs, origins, and user identifiers. Record tested routes, accounts, and tenant information only in access-controlled test evidence—not in this public skill.

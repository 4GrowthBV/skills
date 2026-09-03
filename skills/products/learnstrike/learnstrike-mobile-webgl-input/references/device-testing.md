# Device testing and diagnosis

## Choose the correct test layer

Use the shortest feedback loop that still exercises the suspected layer:

1. Unity tests for layout calculations, activation leases, state transitions, and UI Toolkit structure.
2. Local LearnStrike WebGL build in mobile Chrome and Safari for browser editor, caret, selection, scrolling, and canvas stability.
3. LearnWorlds browser harness hosting MultiChatBoilerplate for nested-iframe viewport relay and host behavior.
4. LearnWorlds Android/iOS app hosting the WebGL module for native WebView viewport, focus, memory, and lifecycle behavior.
5. Native LearnStrike Android/iOS player when shared Unity UI, onboarding, profile, or input-mode code changes.

Do not treat a local-browser pass as proof that a nested iframe or app WebView passes. Conversely, do not apply a LearnWorlds WebView workaround to native LearnStrike builds that never execute the browser bridge.

## Test preconditions

- Identify the exact build directory and content version. Avoid accidentally testing a cached or older build.
- For iOS WebGL builds, use an iOS-supported texture format such as ASTC; DXT failure is a rendering/build compatibility problem, not keyboard evidence.
- Serve WebGL with the headers and transport settings its build expects. Separate server/compression/mixed-content errors from keyboard regressions.
- Keep host-embed and generated-player revisions recorded alongside the Unity/content version.
- Before each measured run, note orientation, browser/app, screen state, whether the keyboard is already connected, and whether the run follows a media return.
- Record device model, OS version, LearnWorlds app version, and Android System WebView version where applicable.

## Passive LearnWorlds USB snapshot

Run the included snapshot before and after a short, repeatable interaction sequence:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\capture-learnworlds-usb-state.ps1
~~~

Pass `-AndroidPackage <learnworlds-package>` when app-specific process, version, foreground-match, renderer, or memory evidence is needed. The default run deliberately avoids assuming or publishing a package identifier. When more than one Android device is attached, pass `-AndroidSerial`. If the iOS proxy uses a different device-list port, pass `-IosDeviceListPort`; the script derives the first device page port from the proxy response unless `-IosPagesPort` is supplied.

The script is deliberately low-impact. It does not tap the device, relaunch the app, clear logcat, create adb forwards, or read DOM/page content. Its default JSON suppresses Android serials/details, iPhone UDIDs/names, inspectable-page IDs/titles/URLs, and process memory. It retains model/OS plus ephemeral iOS `appId`/target type so a Safari A/B run can distinguish target replacement without revealing page content. Use `-IncludeDeviceIdentifiers` only when identifier-level troubleshooting is required, `-IncludeMemory` only for a deliberate measured run, and `-IncludePageMetadata` only in a controlled environment where those fields cannot expose private course or chat information.

The script checks native adb exit codes and reports probe failure instead of silently treating partial output as success. It also rejects an iOS page port when that port is owned by an adb forward or identifies itself as Android DevTools. Treat this rejection as a setup error and restart `ios_webkit_debug_proxy` on a non-overlapping range.

Treat the output as a point-in-time evidence bundle, not as a universal statement about every LearnWorlds app version.

## In-page capability probe

Use [../scripts/learnworlds-webview-capability-probe.js](../scripts/learnworlds-webview-capability-probe.js) in a controlled diagnostic build when the app WebView has no DevTools target. Include it after the page DOM is available, then capture snapshots at named phases:

~~~html
<script src="/diagnostics/learnworlds-webview-capability-probe.js"></script>
<script>
  window.LearnStrikeWebViewProbe.markPhase("keyboard-closed");
  const snapshot = window.LearnStrikeWebViewProbe.snapshot();
</script>
~~~

Supported phases are `keyboard-closed`, `keyboard-open`, `media-open`, `media-returned`, and `first-post-return-tap`. `snapshot()` returns active-element metadata, selection offsets, local viewport/frame geometry, canvas CSS/backing dimensions, fullscreen and Flutter-bridge presence, plus a bounded lifecycle/event buffer. It does not read input values, message payloads, URLs, origins, canvas pixels, or user identifiers, and it never creates a WebGL context. Call `clear()` between controlled sequences and `destroy()` before removing or replacing the diagnostic runtime.

Without DevTools, expose the returned object only through a temporary authenticated test-harness panel or diagnostic transport that preserves the same privacy boundary. Do not add console claims when nobody can read the console, and do not ship a public diagnostics panel in the production player.

## Chrome and Edge DOM inspection

Use whichever Chromium browser is actually connected to the device or automation provider. Chrome and Edge use the same basic DevTools target flow; an open browser window by itself is not enough.

- Android Chrome: open `chrome://inspect/#devices`.
- Android Edge: open `edge://inspect/#devices`.
- Enable device discovery, confirm the exact page or WebView target, and verify its owning app/process before selecting **Inspect**.
- A Chrome-owned target is useful for the standalone/browser-harness control but is not evidence that the LearnWorlds app WebView is inspectable.
- If only one desktop browser is connected to the automation provider, use that browser and report the other as untested rather than assuming access.

For a nested desktop/browser harness, inspect one frame boundary at a time. Start at the top document, identify visible candidate iframes by tag, dimensions, title, and stable IDs, enter the host frame, then the game frame, then the Unity entry document. In Playwright, use chained `frameLocator(...)` calls discovered from the current DOM. Do not hard-code an old frame count or selector without rediscovery.

Never dump an authenticated frame tree indiscriminately. Iframe sources, tab metadata, accessibility trees, and DOM snapshots can include signed URLs, bearer tokens, user identifiers, and chat text. Gather only derived state such as:

- iframe count and sanitized role/size;
- `visualViewport` width, height, offsets, and scale;
- game-frame and canvas rectangles;
- canvas backing width and height;
- active-element tag/type/input mode without its value;
- presence of media/game frames and bounded lifecycle markers.

Discard query strings and fragments; do not retain page text or input values. Prefer the included in-page probe for a stable privacy boundary.

### What can be automated

Run the same bounded state machine in each inspectable environment: baseline, keyboard open, keyboard closed, media open, media close, runtime ready, and first post-return focus. Assert process/frame lifetime and sanitized geometry at every transition.

- Host HTML controls and media overlays can use semantic DOM locators.
- Unity UI rendered into a canvas has no semantic DOM buttons. Use an explicit in-game test hook when available; otherwise use a fresh screenshot plus calibrated coordinates and revalidate the screen before every tap.
- Desktop mobile emulation cannot prove native IME, caret, iOS form-assistant, or real `visualViewport` behavior. Those require a physical device.
- Android app touch and lifecycle checks can be automated through ADB even when its DOM is not exposed. DOM assertions still require an app-owned DevTools target or the in-page probe.
- iOS Safari DOM inspection is easiest through Safari Web Inspector on macOS. LearnWorlds app DOM inspection additionally requires its WKWebView to be inspectable. Reliable iOS touch/keyboard automation normally requires XCUITest or Appium on a provisioned Mac; a Windows WebKit proxy is an inspection aid, not full device automation.

Use a dedicated test account or serialize state-changing flows. Opening and returning from the same media item concurrently on two devices can legitimately produce two server-side continuation events and make an otherwise correct client look duplicated.

## Android inspection

Start by selecting the exact device and identifying the foreground package:

~~~powershell
adb devices -l
adb -s <serial> shell dumpsys activity activities
adb -s <serial> shell dumpsys package <learnworlds-package>
adb -s <serial> shell dumpsys webviewupdate
~~~

Use the serial on every command when multiple devices or emulators are present.

### Keyboard and viewport evidence

Capture input-method state while the LearnWorlds chat editor is focused:

~~~powershell
adb -s <serial> shell dumpsys input_method
~~~

Interpret several signals together:

- mServedView identifies the view that owns the active input connection.
- mIsInputViewShown indicates whether the IME UI is reported as visible.
- mInputShown can disagree on some Android releases and must not be used alone.
- The focused window and soft-input adjustment mode help distinguish WebView resize behavior from Unity layout behavior.



Do not assume Android UI Automator can address HTML controls. Accessibility exposure can vary by app, page, and WebView version. Prefer semantic lookup when verified, but retain coordinate and screenshot fallbacks.

### WebView DevTools

List sockets before forwarding anything:

~~~powershell
adb -s <serial> shell cat /proc/net/unix
adb forward --list
~~~

A generic chrome_devtools_remote socket commonly belongs to Chrome. Do not attribute it to LearnWorlds until the returned target URL/title and owning process agree. An app-owned WebView target normally has a webview_devtools_remote-style socket. If a candidate is verified, forward a free local port and query its JSON target list:

~~~powershell
adb -s <serial> forward tcp:9222 localabstract:<verified-socket-name>
~~~

Remove temporary forwarding after the test. WebView debugging is controlled by native WebView configuration; a non-debuggable package alone does not prove that inspection is disabled. Conversely, when no app-owned target is exposed, page JavaScript cannot enable it.

### Host and renderer lifetime

Track both the LearnWorlds host process and its associated Android System WebView renderer:

~~~powershell
adb -s <serial> shell pidof -s <learnworlds-package>
adb -s <serial> shell dumpsys activity processes
adb -s <serial> shell dumpsys meminfo <learnworlds-package>
adb -s <serial> shell dumpsys meminfo <renderer-pid>
~~~

Use service ownership in dumpsys activity processes to associate a sandboxed WebView renderer with the LearnWorlds package. A stable host PID does not prove that the renderer survived, and host memory alone can miss the largest part of a Unity WebGL workload. Compare host PID and renderer PID across every transition. Add targeted memory snapshots only in a deliberate measured run; they are more expensive than the default state capture. Compare both processes across keyboard, popup/deep-link return, media, background/foreground, and suspected reload transitions.

For logs, preserve the existing buffer and capture a bounded timestamped window. Do not run adb logcat -c on a tester's live device. Filter for the host PID, renderer PID, ActivityManager, low-memory killer, Chromium/WebView, and input-method events. Raw logs can contain private URLs or tokens; retain and share only the minimum fields required to support the finding.

The production LearnWorlds Android app may expose no remote-inspection target. In that case, combine the in-page capability probe, passive USB snapshots, focused logs, and a screen recording. Do not claim console or DOM evidence that was unavailable.

## iOS inspection from Windows

Keep iOS proxy ports separate from Android forwarding and run only one deliberate proxy range. Run `adb forward --list` first and choose ports that do not appear there. A typical command is:

~~~powershell
ios_webkit_debug_proxy -F -c null:9401,:9402-9502
~~~

Query the device list first, then the page port advertised by that response:

~~~text
http://127.0.0.1:9401/json
http://127.0.0.1:9402/json
~~~

Do not trust an advertised port solely because it came from the device-list response. Verify that it is not an adb-forwarded port; if `/json/version` reports an `Android-Package`, it is an Android DevTools endpoint. A collision can otherwise make Android Chrome targets look like iPhone pages. The bundled USB snapshot performs both checks before accepting the page list.

An iPhone in the device list proves that USB pairing and the proxy's device channel are working. An empty page list does not, by itself, prove why LearnWorlds is unavailable.

Use a Safari A/B control:

1. Unlock the iPhone, foreground Safari, open an ordinary page, and query the advertised page endpoint.
2. Without changing the proxy, foreground LearnWorlds on the target screen and query it again.
3. If Safari appears but LearnWorlds does not, the LearnWorlds release app is not exposing an inspectable WKWebView through that path.
4. If neither appears, investigate trust, Web Inspector, Apple device services, proxy age/compatibility, and USB stability before drawing an app-specific conclusion.

On iOS 16.4 and later, WKWebView inspection is an explicit native-app opt-in and is disabled by default. Page HTML, embed code, CSS, and JavaScript cannot change WKWebView.isInspectable. See Apple's documentation for enabling inspection in app-owned web views.

A Windows proxy adds another compatibility layer, so keep the Safari control result with every iOS conclusion. When LearnWorlds is not inspectable, use the in-page probe, a precise scripted interaction sequence, and a screen recording; do not claim console, memory, or DOM evidence that was not available.


### Visual evidence on Windows

Visual capture is separate from WebKit inspection. If 3uTools is installed, Toolbox > Realtime Screen can mirror the connected iPhone and save screenshots over USB; see the [official Realtime Screen instructions](https://www.3u.com/tutorial/details/145/how-to-view-the-realtime-screen-of-your-idevice-using-3utools). This does not expose the LearnWorlds DOM or provide general touch/keyboard automation. Reliable automated input on a stock iPhone normally requires XCUITest/Appium with Xcode on a Mac, or a separately provisioned test setup. Use mirroring to correlate a screen recording or screenshot with the in-page probe timestamps and proxy page count.

3uTools and similar device managers have broad access to the phone. Use only the screen-view/screenshot feature for this test, avoid backup/restore/flash functions, suppress notification previews, and do not retain chat screenshots longer than necessary.

## Measurements to capture

For each keyboard or lifecycle transition, record:

- device, OS, LearnWorlds app version, and WebView/WebKit context;
- tap count until the IME opens;
- active editable element and input mode;
- caret visibility, selection, and text equality between DOM and Unity;
- the highest same-origin accessible visualViewport size, offset, and scale that demonstrably changes;
- host iframe rectangle and any explicitly relayed normalized viewport;
- canvas CSS rectangle and backing width/height before, during, and after the transition;
- compact-layout state, top/tab bar state, quick-reply reservation, and composer position;
- scroll gesture behavior and whether interactive buttons still receive taps;
- keyboard close path: conversation tap versus native keyboard-down/Done;
- Android host PID, associated renderer PID, their memory, and whether an app-owned DevTools socket exists;
- iOS proxy device endpoint, page count, and Safari A/B control result;
- timestamps and logs around any reload or renderer replacement.

Use stable diagnostic event names and a bounded in-page ring buffer when console access is unreliable. Never log message text, phone numbers, user IDs, auth tokens, or other sensitive content as part of viewport diagnostics.

## Fast HTML experiments

When the hypothesis is entirely in browser or host code:

- patch the generated WebGL entry document to test template behavior without rebuilding Unity;
- update the LearnWorlds host snippet to test viewport relay, iframe sizing, or media lifecycle behavior;
- retain a backup or exact diff of the deployed experiment;
- once validated, apply the change to the source template and rebuild before release.

Do not leave a production fix only in a generated build directory. Generated builds are replaceable artifacts and are normally not the Git source of truth.

Changes to onboarding/addressable configuration need a content update. Unity runtime or browser-plugin behavior needs a player build. Plan device iterations so the expensive LearnWorlds deployment is used for integrated validation rather than initial discovery.

## Diagnosing common signatures

### Keyboard needs several taps

Check that the trusted gesture arms proxy focus, the proxy exists by finger-up, and current composer/editor geometry has been published. After media return, specifically check whether the new runtime has a valid composer rectangle when input becomes visible/enabled.

### Keyboard opens and immediately closes

Look for focus loss caused by layout rebuilds, iframe/host resize handlers, Unity focus changes, or an over-broad scroll/tap interceptor. Compare focus events with viewport events rather than assuming the keyboard itself dismissed.

If this happens only after media return, capture focus, blur, host-viewport, and Unity keyboard-state events at sub-second resolution; an ordinary screenshot can miss the short open state. Check that the reconstructed runtime does not consume a stale pre-focus viewport snapshot or interpret its first settling update as a real keyboard-close transition, because either path can blur the newly focused proxy immediately.

### No caret but typing works

Check for transforms, opacity/visibility, caret color, z-index, overlay alignment, or Unity rendering over the editable element. Keep the focused editor untransformed and use at least a 16px browser font.

### Canvas and fonts shrink

Compare native WebView bounds, ancestor/game-frame rectangles, canvas CSS bounds, and canvas backing dimensions separately. Verify both the LearnWorlds game-frame height lock and child canvas freeze. The native visible surface and logical chat region may shrink to the usable viewport; the canvas backing and font scale should not follow transient keyboard-animation sizes.

### Scrolling fails while the keyboard is open

Confirm the browser editor is focused, the gesture starts inside the scroll hit rectangle, buttons are excluded, normalized deltas reach Unity, and the Unity ScrollView has non-zero content/view heights.

### Page reloads after repeated keyboard or media cycles

Capture renderer/process evidence. Look for canvas reallocations, concurrent Unity.Quit()/iframe removal, explicit WebGL context loss, leaked iframe/listener/timer instances, or media and Unity running simultaneously on a memory-constrained device.

A browser pass does not clear the app-WebView case. Repeat the exact sequence in the LearnWorlds app because its native container can resize the ancestor/game frame differently. Include a lower-memory iPhone such as iPhone 13 in repeated-cycle testing; historically it has exposed failures first, but reverify this on every relevant app/OS/build combination.

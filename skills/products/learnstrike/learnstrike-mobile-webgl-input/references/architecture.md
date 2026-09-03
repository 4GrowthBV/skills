# Architecture and design constraints

## Product and deployment model

Keep the product, player target, module, and host distinct:

```text
LearnStrike product
  -> native Unity player for Android/iOS
     -> Unity keyboard path; no DOM or iframe bridge
  -> Unity WebGL player
     -> standalone mobile/desktop browser
     -> MultiChatBoilerplate embedded in LearnWorlds
        -> LearnWorlds browser pages
        -> LearnWorlds native iOS/Android app WebView
```

`MultiChatBoilerplate` is a LearnStrike module. When it runs inside the LearnWorlds native app, the surrounding shell is native but the module remains WebGL. Diagnose it as WebGL inside a WebView, not as a native LearnStrike player.

Onboarding, profile fields, and other LearnStrike modules can reuse the same input-mode or bridge infrastructure without sharing every LearnWorlds-specific behavior. Check which consumer is active before broadening a fix.

## LearnWorlds-hosted WebGL layer model

The LearnWorlds-hosted WebGL page is a stack, not a single viewport:

```text
LearnWorlds native app WebView
  -> LearnWorlds top document
    -> zero or more LearnWorlds/integration frames
      -> custom host embed
        -> game iframe
          -> Unity WebGL entry document + canvas + Unity-generated editable proxy
```

Identify the actual Android and iOS host implementations at runtime. If library or native view types are observed, treat them as version-specific evidence rather than a permanent LearnWorlds contract. An Android artifact cannot prove the iOS configuration.

On mobile, determine empirically which browsing context receives the useful `visualViewport` change. An inner WebGL frame can retain a full layout viewport and therefore cannot infer keyboard occlusion reliably from its own `innerHeight`. Cross-origin frames cannot read the true top window directly.

## Responsibility map

Locate these responsibilities in the current checkout rather than relying on historical filenames:

- the maintained WebGL entry template coordinates proxy focus, editor presentation, viewport state, canvas stability, touch forwarding, and release acknowledgement;
- the WebGL JavaScript plugin exposes the narrow Unity-to-browser API;
- the shared Unity bridge owns lifecycle, activation leases, normalized geometry, input modes, and layout calculation;
- the active chat/onboarding/profile view publishes geometry and owns product state, validation, scrolling, and focus cleanup;
- responsive chat code owns compact navigation, quick-reply reservation, and composer spacing;
- onboarding configuration expresses per-field keyboard intent and maps it to both WebGL and native Unity input;
- the LearnWorlds host integration owns top-level viewport relay, stable iframe sizing, media presentation, low-memory teardown, and runtime restoration.

When ownership is unclear, trace the call and message flow in both directions. Do not edit the first matching file until its callers and deployment path confirm that it is the maintained source of truth.

## Editable proxy contract

Unity UI Toolkit remains the logical control. The browser focuses Unity's generated editable proxy because mobile browsers only show an IME for a real editable DOM element during a trusted gesture.

While focused:

- normalize the proxy's semantics (`inputmode`, maximum length, multiline behavior, autocorrection, capitalization, and enter-key hint);
- align it to the normalized UI Toolkit editor rectangle;
- keep the focused element untransformed and at a browser font size of at least 16px to avoid invisible carets and iOS focus zoom;
- make the browser editor the visible caret/selection surface while keeping Unity text synchronized;
- avoid a separately managed DOM field with independent value, validation, or submission logic.

Before keyboard occlusion is measurable, the proxy may need to remain a minimal focus target and a non-interactive mirror can maintain visual continuity. Once the keyboard is open, position the real editor over the Unity composer.

Do not redesign around `contenteditable` solely to hide iOS's form assistant. It remains an editable WebKit responder and does not reliably remove Previous/Next/Done. Only the owner of a native `WKWebView` can customize native accessory views.

## Viewport and canvas flow

1. The game frame subscribes to the host viewport relay with a versioned `postMessage` contract.
2. The host walks only the same-origin-accessible frame chain and transforms the game-frame rectangle into the highest accessible ancestor's coordinates, including frame scaling.
3. It intersects that rectangle with the `visualViewport` that was observed to react to the IME and sends normalized `x`, `y`, `width`, and `height` to the verified active game frame. If the useful viewport is beyond a cross-origin boundary, the owning frame must participate in the relay.
4. The WebGL template combines host geometry with local focus/viewport observations and reports normalized keyboard/viewport state to Unity.
5. The Unity-side layout calculation maps CSS geometry back to UI Toolkit units:

   `unitsPerCssPixel = rootHeight / layoutHeight`

   `top = offsetTop * unitsPerCssPixel`

   `height = viewportHeight * unitsPerCssPixel`, clamped to the remaining root height.
6. Chat or onboarding fits its logical content into that visible region while the actual canvas size remains stable.

The custom LearnWorlds embed host locks the game iframe to its measured pre-keyboard height and refreshes that baseline only after the keyboard is closed, after orientation settles, or after a new game frame loads. This is integration-owned behavior, not a capability supplied by the native LearnWorlds app. The WebGL template independently freezes the canvas because a native WebView can resize the child document even when the parent iframe height is fixed.

Avoid using transient keyboard animation frames to resize the WebGL drawing buffer. On memory-constrained iPhones, reallocating a large canvas or rapidly destroying graphics resources can cause renderer termination or a visible page reload.

The observed high-risk chain is: the native host changes its visible viewport or an ancestor frame during the keyboard animation; an unstabilized child follows that size; Unity reallocates a large WebGL drawing buffer; memory pressure rises; and the renderer may be terminated or visibly reload. This chain is a diagnostic hypothesis until canvas backing dimensions plus process/log evidence confirm it. A smaller accessibility or iframe rectangle alone proves only that the visible host surface changed.

Historically, a lower-memory iPhone 13 has been the least stable regression device for repeated keyboard and media transitions. Keep it in the matrix, but treat the result as build-, OS-, and host-version-specific rather than as a permanent platform rule. Passing in Safari does not clear the LearnWorlds app: its WKWebView may resize the game-frame stack differently.

## Focus and geometry lifecycle

Geometry publication is not a one-time initialization step. Refresh normalized editor, composer, send, scroll, and interactive hit rectangles after:

- the input becomes visible;
- input reactivation;
- a tab or screen becomes active;
- UI Toolkit geometry changes;
- compact keyboard transitions finish;
- scrolling moves the active editor;
- orientation changes;
- another bridge consumer disposes;
- a media return creates a new iframe/runtime.

This is critical after media return. A newly created Unity runtime may create or retain an unfocused proxy before valid composer geometry has been republished. Broadly focusing any tap is unsafe; refresh the Unity geometry at the lifecycle boundary, and keep any browser fallback restricted to the composer region.

Bridge consumers acquire an activation lease, subscribe to shared events, and dispose/unsubscribe symmetrically. When one of multiple consumers releases its lease, the bridge requests a geometry refresh from whoever remains active. Tests must dispose views so static counts and subscribers do not leak across fixtures.

## Touch and scroll behavior

When the browser editor overlays the canvas, normal Unity pointer routing is no longer sufficient. The bridge therefore works with normalized hit rectangles:

- composer/editor rectangle;
- send-button rectangle;
- conversation/onboarding scroll rectangle;
- interactive exclusion rectangles for buttons and other controls.

Only capture a gesture after confirming it begins in the intended scroll region and outside exclusions. Track movement before deciding whether it was a drag. A drag forwards normalized deltas to Unity and preserves focus; a simple tap on history blurs the editor and dismisses the keyboard. Do not suppress every pointer-down in a `ScrollView`, because that consumes Next, Submit, Skip, tabs, and overlay controls.

Android Back or the keyboard-down button can remove the native input connection while UI Toolkit still believes its field is focused. When viewport state changes from open to closed, blur stale Unity focus so a later tap can create/reconnect the proxy.

## Compact chat layout

Keyboard-open layout intentionally prioritizes message history and the composer:

- collapse the top navigation and tab bar with reversible transitions;
- reduce quick-reply padding and reserved spacing;
- move quick replies below the usable keyboard viewport instead of encouraging interaction through iOS's translucent form assistant;
- keep the character counter inline and hidden until near the limit;
- remove avoidable composer whitespace;
- refresh response-button reservations after composer growth and transition completion.

If a navigation height was not measurable before collapse, remove inline `height` and `max-height` constraints on close so stylesheet sizing can recover.

## Input modes and onboarding

A shared input-mode abstraction spans WebGL and native builds. Supported intent includes text, telephone, email, numeric, decimal, URL, and search. Onboarding definitions carry the setting; the screen builder maps it to Unity's native keyboard type, and the WebGL bridge maps it to the HTML `inputmode`.

Register fields generically rather than naming individual onboarding screens. Track the active field, its editor element, and its ancestor `ScrollView`; scroll the field and relevant validation/context text into view without clearing messages merely because focus changed.

For native LearnStrike players, stop at the Unity keyboard mapping and UI Toolkit behavior. For WebGL, continue through the DOM editor and viewport bridge. LearnWorlds host relay and media teardown apply only when that WebGL player is inside the LearnWorlds integration.

## Media-card low-memory lifecycle

Opening media in the custom LearnWorlds embed host intentionally replaces the WebGL runtime:

1. Unity prepares a return record containing a one-time media-session ID and card ID.
2. The host keeps the active record in memory and best-effort local storage, scoped to the current embed runtime and a bounded TTL.
3. The host shows the media loading UI and requests a release acknowledgement from the current game frame.
4. The child stops keyboard/viewport subscriptions and acknowledges that it is ready for parent-owned removal.
5. The child must not independently quit the Unity runtime or force graphics-context loss while a host timeout can concurrently remove the iframe. Two teardown owners can race and cause unstable reloads in memory-constrained WebViews.
6. The host removes the game iframe, waits for teardown to settle, and creates the media iframe.
7. Closing media records the return phase, destroys the media iframe, shows a lightweight restoration overlay, and creates a fresh game iframe with bounded return state.
8. The new Unity runtime restores chat history, handles the pending media return once, emits the follow-up, and reports readiness; only then does the host hide the restoration overlay.

The effective memory mitigation is to avoid keeping the large chat WebGL runtime alive behind the media view. "Release" here means that the child stops its keyboard/viewport activity and acknowledges parent-owned removal; the host then removes the game iframe before creating media. Do not add a competing child-side `Unity.Quit()` or forced WebGL-context loss when the parent can remove the frame on a timeout.

Use monotonically changing tokens/session IDs so late iframe events from an earlier open/close cycle cannot mutate the current flow. Validate `event.source`, expected origin, message type, version, and media-session ID on every cross-frame message.

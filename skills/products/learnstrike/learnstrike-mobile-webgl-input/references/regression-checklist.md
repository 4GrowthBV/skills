# Regression checklist

Run the applicable automated checks first, then execute the same behavioral sequence on Android and iOS. Repeat critical transitions; a single pass does not expose lifecycle or memory regressions.

## Automated checks

- Keyboard-layout tests: closed state, iPhone viewport, panned Android viewport, zoomed viewport, activation leases, surviving-consumer refresh, and input-mode mappings.
- Chat-view tests: disposal in teardown, send/focus behavior, compact reply spacing, navigation collapse/restore including unknown initial height, inline character counter, composer growth, and button behavior.
- Add coverage when geometry is republished after input visibility/enablement or a reconstructed runtime; this lifecycle edge must not rely only on the initial 100 ms setup refresh.
- Add onboarding tests when changing generic field registration, context scrolling, message persistence, or config-driven input modes.
- Run syntax validation for every changed inline script in the WebGL template and LearnWorlds embed.
- When changing the diagnostic helpers, parse the PowerShell script, run `node --check` on the in-page probe, and verify that a default USB snapshot contains no Android serial, iPhone UDID/name, or page URL/title.

## Chat, keyboard closed

- Chat history and quick replies load.
- Conversation and media/library navigation plus menu controls work.
- Composer size, whitespace, and counter behavior are correct.
- Text wrapping is stable and does not change merely because the keyboard was previously opened.

## Keyboard open and editing

- First intentional composer tap opens the keyboard; record any extra taps.
- Correct keyboard layout appears for text, telephone, email, numeric, decimal, URL, and search fields as applicable.
- In the LearnWorlds iOS app, compare a normal two-field form with an isolated single input and capture the native Previous/Next/Done assistant visually; do not infer its presence or removal from DOM state. On Android, record the keyboard action key separately.
- Caret is visible and aligned with the Unity composer.
- Typing, selection, replacement, deletion, autocorrection, multiline wrapping, and maximum length remain synchronized.
- Canvas dimensions and font scale remain stable; only logical content is fitted into the visible viewport.
- Top navigation and tab bar collapse and restore smoothly.
- Quick replies use compact spacing and move outside the usable keyboard viewport without becoming accidentally clickable through iOS's translucent form assistant.
- Character counter appears only near the limit.
- Conversation scroll works, including inertia; dragging retains focus.
- A tap on history dismisses the keyboard without sending or selecting an unrelated control.
- Native keyboard-down/Done closes cleanly; the next composer tap reopens it.
- Send works and focus behavior matches the intended chat flow.
- Next, Submit, Skip, tabs, menu, and overlay buttons remain tappable when they overlap a scroll viewport.

## Onboarding and other forms

- Test at least one normal text field and every telephone-configured onboarding screen used by the product.
- Telephone fields open the phone keyboard from config rather than screen-name-specific code.
- The active field and its explanatory/validation message remain in view.
- Focusing a field does not clear an unrelated loading or validation message.
- DOM text and Unity text stay synchronized after messages appear/disappear and after scrolling.
- Opening the keyboard does not reset the onboarding slide or restart its controller.
- Profile-tab input fields use the expected keyboard and survive tab changes.
- Multiple chat/onboarding consumers do not disable each other's bridge state; dispose/unsubscribe cleanly.

## Media-card round trip

Perform this sequence at least twice on a memory-constrained iPhone and once on Android:

1. Open and close the keyboard before media.
2. Open Bibliotheek and select a media card.
3. Verify media loads and Unity is no longer consuming the large WebGL runtime concurrently.
4. Close media with the provided back control.
5. Verify the restoration overlay remains until the new chat runtime reports ready.
6. Verify history and the correct follow-up message are restored exactly once.
7. Tap the composer immediately after return.
8. Verify the keyboard opens on the first tap, the caret appears, text is synchronized, and scrolling works.
9. Repeat with a second media card and recheck process/renderer stability.

Failure after step 7 usually indicates stale or missing geometry/focus in the newly created runtime, even when initial startup works.

## Environment matrix

Choose rows according to the changed layer. Shared Unity/config changes require both WebGL and native smoke tests; LearnWorlds-only HTML changes do not require rebuilding native LearnStrike players.

| Unity player | Host | Android | iOS |
| --- | --- | --- | --- |
| LearnStrike WebGL | Standalone browser | Chrome | Safari |
| LearnStrike WebGL / `MultiChatBoilerplate` | LearnWorlds browser harness with nested frames | Chrome | Safari |
| LearnStrike WebGL / `MultiChatBoilerplate` | LearnWorlds native app WebView | App test | App test |
| LearnStrike native player | Native LearnStrike app | Native smoke test | Native smoke test |

Add portrait/landscape and browser zoom/orientation cases when viewport code changes. Test desktop WebGL and an unrelated microgame when shared template or bridge activation behavior changes. Native LearnStrike testing focuses on Unity keyboard type, field behavior, layout, and shared configuration; DOM/canvas/iframe assertions do not apply there.

## Release evidence

Keep reproduction evidence access-controlled and publish only sanitized conclusions. Record:

- device/OS, LearnWorlds app version, and Android System WebView or iOS WebKit context;
- Android host PID, associated WebView renderer PID, IME served view, and whether a LearnWorlds DevTools socket was actually present; include app/renderer memory only when memory or lifecycle is under investigation;
- iOS proxy device/page endpoints and the result of a Safari control test when the LearnWorlds page is not exposed;
- Unity build and content version;
- template/embed revision;
- environments and sequences tested;
- screenshots or recordings for visual transitions;
- for deep-link, popup, and fullscreen probes: launch mechanism, receiving activity/app, whether the same page instance and host/renderer processes survived, and whether native chrome disappeared;
- for popup course navigation, verify that the receiving context is authenticated; opening the expected URL in an external browser is a failure when the user must remain logged in;
- for current-view course navigation, verify the app Back destination; if Back returns home, treat navigation away as terminal and persist a bounded continuation record before leaving;
- on Android, test the app-provided Back control and system Back separately; do not assume system Back uses WebView history;
- when claiming app deep-link support, record the receiving application/activity and the relevant declared public-link filters. An internal application route or authentication callback scheme is not a public app deep link;
- console/log/process evidence for crashes or reloads;
- automated test results;
- known limitations, especially unavailable WebView inspection.

Do not mark the work complete with unresolved first-tap focus failure after media return, an unexplained renderer reload, or a fix that exists only in a generated build artifact.

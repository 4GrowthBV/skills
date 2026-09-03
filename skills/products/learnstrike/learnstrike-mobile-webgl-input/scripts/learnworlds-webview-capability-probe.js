(function installLearnStrikeWebViewProbe(global) {
  "use strict";

  const previous = global.LearnStrikeWebViewProbe;
  if (previous && typeof previous.destroy === "function") {
    previous.destroy();
  }

  const MAX_EVENTS = 100;
  const startedAt = Date.now();
  const listeners = [];
  const events = [];
  const allowedPhases = new Set([
    "initial",
    "keyboard-closed",
    "keyboard-open",
    "media-open",
    "media-returned",
    "first-post-return-tap",
  ]);
  let phase = "initial";
  let destroyed = false;

  function finiteNumber(value) {
    return Number.isFinite(value) ? Math.round(value * 100) / 100 : null;
  }

  function rectangle(element) {
    if (!element || typeof element.getBoundingClientRect !== "function") {
      return null;
    }

    const rect = element.getBoundingClientRect();
    return {
      x: finiteNumber(rect.x),
      y: finiteNumber(rect.y),
      width: finiteNumber(rect.width),
      height: finiteNumber(rect.height),
    };
  }

  function activeElementState() {
    const element = document.activeElement;
    if (!element) {
      return null;
    }

    const result = {
      tag: String(element.tagName || "").toLowerCase() || null,
      type:
        typeof element.type === "string"
          ? element.type.toLowerCase()
          : null,
      inputMode:
        typeof element.inputMode === "string" && element.inputMode
          ? element.inputMode
          : null,
      contentEditable: Boolean(element.isContentEditable),
      rect: rectangle(element),
    };

    try {
      result.selectionStart = Number.isInteger(element.selectionStart)
        ? element.selectionStart
        : null;
      result.selectionEnd = Number.isInteger(element.selectionEnd)
        ? element.selectionEnd
        : null;
    } catch (_) {
      result.selectionStart = null;
      result.selectionEnd = null;
    }

    return result;
  }

  function viewportState() {
    const visual = global.visualViewport;
    return {
      innerWidth: finiteNumber(global.innerWidth),
      innerHeight: finiteNumber(global.innerHeight),
      documentClientWidth: finiteNumber(document.documentElement.clientWidth),
      documentClientHeight: finiteNumber(document.documentElement.clientHeight),
      scrollX: finiteNumber(global.scrollX),
      scrollY: finiteNumber(global.scrollY),
      visualViewport: visual
        ? {
            width: finiteNumber(visual.width),
            height: finiteNumber(visual.height),
            offsetLeft: finiteNumber(visual.offsetLeft),
            offsetTop: finiteNumber(visual.offsetTop),
            pageLeft: finiteNumber(visual.pageLeft),
            pageTop: finiteNumber(visual.pageTop),
            scale: finiteNumber(visual.scale),
          }
        : null,
    };
  }

  function frameState() {
    let current = global;
    let accessibleAncestorDepth = 0;
    let reachedTop = current === current.top;
    let blockedAtDepth = null;

    while (!reachedTop) {
      try {
        const parent = current.parent;
        void parent.document.documentElement;
        current = parent;
        accessibleAncestorDepth += 1;
        reachedTop = current === current.top;
      } catch (_) {
        blockedAtDepth = accessibleAncestorDepth + 1;
        break;
      }
    }

    let frameElementRect = null;
    try {
      frameElementRect = rectangle(global.frameElement);
    } catch (_) {
      frameElementRect = null;
    }

    return {
      isTop: global === global.top,
      accessibleAncestorDepth,
      reachedTop,
      blockedAtDepth,
      frameElementRect,
    };
  }

  function canvasState() {
    return Array.from(document.querySelectorAll("canvas"))
      .slice(0, 8)
      .map((canvas, index) => ({
        index: index + 1,
        cssRect: rectangle(canvas),
        backingWidth: finiteNumber(canvas.width),
        backingHeight: finiteNumber(canvas.height),
      }));
  }

  function bridgeState() {
    const bridge = global.flutter_inappwebview;
    return {
      objectPresent: Boolean(bridge),
      callHandlerType: bridge ? typeof bridge.callHandler : "undefined",
    };
  }

  function fullscreenState() {
    return {
      enabled: Boolean(document.fullscreenEnabled),
      active: Boolean(document.fullscreenElement),
      elementTag: document.fullscreenElement
        ? String(document.fullscreenElement.tagName || "").toLowerCase() || null
        : null,
    };
  }

  function compactState() {
    return {
      elapsedMs: Date.now() - startedAt,
      phase,
      visibility: document.visibilityState,
      activeElement: activeElementState(),
      viewport: viewportState(),
      fullscreen: fullscreenState(),
    };
  }

  function record(kind, details) {
    if (destroyed) {
      return;
    }

    events.push({
      kind,
      ...compactState(),
      ...(details || {}),
    });
    if (events.length > MAX_EVENTS) {
      events.splice(0, events.length - MAX_EVENTS);
    }
  }

  function listen(target, name, handler, options) {
    if (!target || typeof target.addEventListener !== "function") {
      return;
    }

    target.addEventListener(name, handler, options);
    listeners.push(() => target.removeEventListener(name, handler, options));
  }

  function sourceKind(source) {
    if (source === global) {
      return "self";
    }
    if (source === global.parent) {
      return "parent";
    }
    if (source === global.top) {
      return "top";
    }
    return "other";
  }

  ["focus", "blur", "resize", "orientationchange"].forEach((name) => {
    listen(global, name, () => record(`window-${name}`), { passive: true });
  });
  ["pageshow", "pagehide"].forEach((name) => {
    listen(
      global,
      name,
      (event) => record(`window-${name}`, { persisted: Boolean(event.persisted) }),
      { passive: true }
    );
  });
  listen(
    global,
    "message",
    (event) =>
      record("window-message", {
        source: sourceKind(event.source),
        dataKind: Array.isArray(event.data) ? "array" : typeof event.data,
      }),
    { passive: true }
  );
  listen(global, "flutterInAppWebViewPlatformReady", () =>
    record("flutter-platform-ready")
  );

  [
    "focusin",
    "focusout",
    "visibilitychange",
    "fullscreenchange",
    "fullscreenerror",
  ].forEach((name) => {
    listen(document, name, () => record(`document-${name}`), { passive: true });
  });

  if (global.visualViewport) {
    ["resize", "scroll"].forEach((name) => {
      listen(
        global.visualViewport,
        name,
        () => record(`visual-viewport-${name}`),
        { passive: true }
      );
    });
  }

  const api = {
    snapshot() {
      return {
        schemaVersion: 1,
        capturedAtUtc: new Date().toISOString(),
        elapsedMs: Date.now() - startedAt,
        phase,
        privacy:
          "No input values, message data, URLs, origins, user identifiers, or canvas pixels are collected.",
        document: {
          visibility: document.visibilityState,
          hasFocus: document.hasFocus(),
          activeElement: activeElementState(),
        },
        viewport: viewportState(),
        frame: frameState(),
        fullscreen: fullscreenState(),
        bridge: bridgeState(),
        canvases: canvasState(),
        events: events.slice(),
      };
    },
    markPhase(nextPhase) {
      if (!allowedPhases.has(nextPhase)) {
        throw new Error(
          `Unsupported diagnostic phase. Use one of: ${Array.from(allowedPhases).join(", ")}.`
        );
      }
      phase = nextPhase;
      record("phase-marked");
    },
    clear() {
      events.length = 0;
      record("events-cleared");
    },
    destroy() {
      if (destroyed) {
        return;
      }
      destroyed = true;
      listeners.splice(0).forEach((remove) => remove());
      if (global.LearnStrikeWebViewProbe === api) {
        delete global.LearnStrikeWebViewProbe;
      }
    },
  };

  global.LearnStrikeWebViewProbe = api;
  record("probe-installed");
})(window);

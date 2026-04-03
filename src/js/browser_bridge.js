// Copyright 2026 Lloyd Anthony Ganal Balisacan <lloyd.agb@pm.me>
// Licensed under the Apache License, Version 2.0.
// See the LICENSE file for details.

// Reusable browser bridge for Zig Wasm projects.
//
// This runtime is intentionally thin:
// - instantiate the Wasm module
// - expose the expected host imports
// - move strings across the Wasm boundary
// - bridge generic browser capabilities back into exported callbacks
//
// Expected Wasm exports:
// - memory
// - allocBytes(len)
// - freeBytes(ptr, len)
//
// Optional Wasm exports for async callbacks:
// - bridgeReceiveString(kind, requestId, ptr, len)
// - bridgeReceiveFetch(requestId, ok, status, ptr, len)
// - bridgeTimerFired(timerId)

export function createBrowserBridge(options = {}) {
  const config = {
    logSelector: "#log",
    wasmUrl: "./app.wasm",
    imports: {},
    ...options,
  };

  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  const logElement = resolveLogElement(config.logSelector);
  let instance = null;
  const timeoutHandles = new Map();

  function append(message) {
    if (logElement) {
      logElement.textContent += `\n${message}`;
    }
  }

  function warn(message, error) {
    append(`bridge warning: ${message}`);
    if (error !== undefined) {
      console.warn(`bridge warning: ${message}`, error);
      return;
    }
    console.warn(`bridge warning: ${message}`);
  }

  function u32(value) {
    return Number(value) >>> 0;
  }

  function requireInstance() {
    if (!instance) {
      throw new Error("browser bridge is not instantiated yet");
    }
    return instance;
  }

  function getMemory() {
    const activeInstance = requireInstance();
    const memory = activeInstance.exports.memory;
    if (!(memory instanceof WebAssembly.Memory)) {
      throw new Error("wasm export 'memory' is missing or invalid");
    }
    return memory;
  }

  function getRequiredExport(name) {
    const activeInstance = requireInstance();
    const value = activeInstance.exports[name];
    if (typeof value !== "function") {
      throw new Error(`wasm export '${name}' is missing`);
    }
    return value;
  }

  function readString(ptr, len) {
    const byteOffset = u32(ptr);
    const byteLength = u32(len);
    if (byteLength === 0) {
      return "";
    }

    const bytes = new Uint8Array(getMemory().buffer, byteOffset, byteLength);
    return decoder.decode(bytes);
  }

  function withWasmString(text, fn) {
    const encoded = encoder.encode(text);
    const allocBytes = getRequiredExport("allocBytes");
    const freeBytes = getRequiredExport("freeBytes");
    const ptr = u32(allocBytes(encoded.length));
    if (!ptr && encoded.length !== 0) {
      throw new Error("allocBytes returned 0");
    }

    try {
      if (encoded.length !== 0) {
        const bytes = new Uint8Array(getMemory().buffer, ptr, encoded.length);
        bytes.set(encoded);
      }
      return fn(ptr, encoded.length);
    } finally {
      freeBytes(ptr, encoded.length);
    }
  }

  function getElementById(id) {
    const doc = getDocument();
    if (!doc) {
      warn(`document is unavailable while looking up #${id}`);
      return null;
    }

    const element = doc.getElementById(id);
    if (!element) {
      warn(`missing element #${id}`);
    }
    return element;
  }

  function deliverString(kind, requestId, text) {
    const activeInstance = instance;
    if (!activeInstance) {
      warn("dropping string callback because wasm is not instantiated");
      return;
    }

    if (typeof activeInstance.exports.bridgeReceiveString !== "function") {
      warn("bridgeReceiveString export is missing");
      return;
    }

    withWasmString(text, (ptr, len) => {
      activeInstance.exports.bridgeReceiveString(kind, requestId, ptr, len);
    });
  }

  function deliverFetch(requestId, ok, status, text) {
    const activeInstance = instance;
    if (!activeInstance) {
      warn("dropping fetch callback because wasm is not instantiated");
      return;
    }

    if (typeof activeInstance.exports.bridgeReceiveFetch !== "function") {
      warn("bridgeReceiveFetch export is missing");
      return;
    }

    withWasmString(text, (ptr, len) => {
      activeInstance.exports.bridgeReceiveFetch(requestId, ok ? 1 : 0, status, ptr, len);
    });
  }

  function deliverTimer(timerId) {
    const activeInstance = instance;
    if (!activeInstance) {
      warn(`dropping timer ${timerId} because wasm is not instantiated`);
      return;
    }

    if (typeof activeInstance.exports.bridgeTimerFired !== "function") {
      warn("bridgeTimerFired export is missing");
      return;
    }

    activeInstance.exports.bridgeTimerFired(timerId);
  }

  const baseImports = {
    env: {
      js_log(ptr, len) {
        const message = readString(ptr, len);
        append(`zig -> js: ${message}`);
        console.log(message);
      },
      js_error(ptr, len) {
        const message = readString(ptr, len);
        append(`zig error -> js: ${message}`);
        console.error(message);
      },
      js_now_ms() {
        if (typeof performance?.now === "function") {
          return performance.now();
        }
        return Date.now();
      },
      js_set_text_by_id(idPtr, idLen, textPtr, textLen) {
        const id = readString(idPtr, idLen);
        const element = getElementById(id);
        if (element) {
          element.textContent = readString(textPtr, textLen);
        }
      },
      js_set_html_by_id(idPtr, idLen, htmlPtr, htmlLen) {
        const id = readString(idPtr, idLen);
        const element = getElementById(id);
        if (element) {
          element.innerHTML = readString(htmlPtr, htmlLen);
        }
      },
      js_set_value_by_id(idPtr, idLen, valuePtr, valueLen) {
        const id = readString(idPtr, idLen);
        const element = getElementById(id);
        if (element && "value" in element) {
          element.value = readString(valuePtr, valueLen);
        }
      },
      js_set_checked_by_id(idPtr, idLen, checked) {
        const id = readString(idPtr, idLen);
        const element = getElementById(id);
        if (element instanceof HTMLInputElement) {
          element.checked = checked === 1;
        }
      },
      js_set_attribute_by_id(idPtr, idLen, attrPtr, attrLen, valuePtr, valueLen) {
        const id = readString(idPtr, idLen);
        const attr = readString(attrPtr, attrLen);
        const value = readString(valuePtr, valueLen);
        const element = getElementById(id);
        if (element) {
          element.setAttribute(attr, value);
        }
      },
      js_set_disabled_by_id(idPtr, idLen, disabled) {
        const id = readString(idPtr, idLen);
        const element = getElementById(id);
        if (element && "disabled" in element) {
          element.disabled = disabled === 1;
        }
      },
      js_get_value_by_id(requestId, idPtr, idLen) {
        const id = readString(idPtr, idLen);
        const element = getElementById(id);
        const value = element && "value" in element ? String(element.value) : "";
        deliverString(2, requestId, value);
      },
      js_get_checked_by_id(requestId, idPtr, idLen) {
        const id = readString(idPtr, idLen);
        const element = getElementById(id);
        const checked = element instanceof HTMLInputElement && element.checked ? "1" : "";
        deliverString(2, requestId, checked);
      },
      js_storage_set(kind, keyPtr, keyLen, valuePtr, valueLen) {
        const storage = getStorage(kind);
        if (!storage) {
          return;
        }

        try {
          storage.setItem(readString(keyPtr, keyLen), readString(valuePtr, valueLen));
        } catch (error) {
          warn("storage set failed", error);
        }
      },
      js_storage_get(kind, requestId, keyPtr, keyLen) {
        const storage = getStorage(kind);
        const key = readString(keyPtr, keyLen);
        if (!storage) {
          deliverString(1, requestId, "");
          return;
        }

        try {
          deliverString(1, requestId, storage.getItem(key) ?? "");
        } catch (error) {
          warn("storage get failed", error);
          deliverString(1, requestId, "");
        }
      },
      js_storage_remove(kind, keyPtr, keyLen) {
        const storage = getStorage(kind);
        if (!storage) {
          return;
        }

        try {
          storage.removeItem(readString(keyPtr, keyLen));
        } catch (error) {
          warn("storage remove failed", error);
        }
      },
      js_fetch_text(requestId, methodPtr, methodLen, urlPtr, urlLen, bodyPtr, bodyLen) {
        const method = readString(methodPtr, methodLen);
        const url = readString(urlPtr, urlLen);
        const body = readString(bodyPtr, bodyLen);

        if (typeof fetch !== "function") {
          warn("fetch API is unavailable");
          deliverFetch(requestId, false, 0, "fetch API is unavailable");
          return;
        }

        fetch(url, {
          method,
          body: bodyLen === 0 ? undefined : body,
        })
          .then(async (response) => {
            const text = await response.text();
            deliverFetch(requestId, response.ok, response.status, text);
          })
          .catch((error) => {
            console.error(error);
            deliverFetch(requestId, false, 0, String(error));
          });
      },
      js_set_timeout(timerId, delayMs) {
        const scheduler = globalThis?.setTimeout;
        if (typeof scheduler !== "function") {
          warn(`setTimeout is unavailable for timer ${timerId}`);
          return;
        }

        const handle = scheduler(() => {
          timeoutHandles.delete(timerId);
          deliverTimer(timerId);
        }, delayMs);
        timeoutHandles.set(timerId, handle);
      },
      js_clear_timeout(timerId) {
        const handle = timeoutHandles.get(timerId);
        if (handle !== undefined) {
          if (typeof globalThis?.clearTimeout === "function") {
            globalThis.clearTimeout(handle);
          }
          timeoutHandles.delete(timerId);
        }
      },
      js_history_push(urlPtr, urlLen) {
        const url = readString(urlPtr, urlLen);
        if (typeof history?.pushState !== "function") {
          warn(`history.pushState is unavailable for url ${url}`);
          return;
        }

        try {
          history.pushState({}, "", url);
        } catch (error) {
          warn(`history.pushState failed for url ${url}`, error);
        }
      },
      js_set_document_title(titlePtr, titleLen) {
        const doc = getDocument();
        if (!doc) {
          warn("document is unavailable while setting title");
          return;
        }
        doc.title = readString(titlePtr, titleLen);
      },
      js_toggle_class_by_id(idPtr, idLen, classPtr, classLen, present) {
        const id = readString(idPtr, idLen);
        const className = readString(classPtr, classLen);
        const element = getElementById(id);
        if (element) {
          element.classList.toggle(className, present === 1);
        }
      },
      js_toggle_class_on_selector(selectorPtr, selectorLen, classPtr, classLen, present) {
        const doc = getDocument();
        if (!doc) {
          warn("document is unavailable while toggling selector classes");
          return;
        }

        const selector = readString(selectorPtr, selectorLen);
        const className = readString(classPtr, classLen);
        for (const element of doc.querySelectorAll(selector)) {
          element.classList.toggle(className, present === 1);
        }
      },
      js_focus_by_id(idPtr, idLen) {
        const id = readString(idPtr, idLen);
        const element = getElementById(id);
        if (element && "focus" in element) {
          element.focus();
        }
      },
      js_scroll_into_view_by_selector(selectorPtr, selectorLen) {
        const doc = getDocument();
        if (!doc) {
          warn("document is unavailable while scrolling into view");
          return;
        }

        const selector = readString(selectorPtr, selectorLen);
        const element = doc.querySelector(selector);
        if (element instanceof HTMLElement) {
          element.scrollIntoView({ block: "nearest" });
        }
      },
    },
  };

  const imports = mergeImports(baseImports, config.imports);

  async function instantiate() {
    if (typeof fetch !== "function") {
      throw new Error("fetch API is unavailable and the wasm module cannot be loaded");
    }

    const response = await fetch(config.wasmUrl);
    if (!response.ok) {
      throw new Error(`fetch failed: ${response.status} ${response.statusText}`);
    }

    const bytes = await response.arrayBuffer();
    const wasmModule = await WebAssembly.instantiate(bytes, imports);
    instance = wasmModule.instance;
    validateRequiredExports(instance);
    return instance;
  }

  return {
    append,
    get instance() {
      return instance;
    },
    imports,
    instantiate,
    readString,
    withWasmString,
  };
}

function getDocument() {
  return typeof document === "object" ? document : null;
}

function resolveLogElement(logSelector) {
  if (!logSelector) {
    return null;
  }

  const doc = getDocument();
  if (!doc) {
    return null;
  }

  return typeof logSelector === "string"
    ? doc.querySelector(logSelector)
    : logSelector;
}

function getStorage(kind) {
  try {
    return kind === 0 ? globalThis.localStorage : globalThis.sessionStorage;
  } catch (error) {
    console.warn("bridge warning: storage access failed", error);
    return null;
  }
}

function validateRequiredExports(instance) {
  const { exports } = instance;
  if (!(exports.memory instanceof WebAssembly.Memory)) {
    throw new Error("wasm export 'memory' is missing or invalid");
  }
  if (typeof exports.allocBytes !== "function") {
    throw new Error("wasm export 'allocBytes' is missing");
  }
  if (typeof exports.freeBytes !== "function") {
    throw new Error("wasm export 'freeBytes' is missing");
  }
}

function mergeImports(baseImports, extraImports) {
  const result = { ...baseImports };

  for (const [namespace, value] of Object.entries(extraImports)) {
    result[namespace] = {
      ...(result[namespace] ?? {}),
      ...value,
    };
  }

  return result;
}

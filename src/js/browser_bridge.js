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
  const logElement = typeof config.logSelector === "string"
    ? document.querySelector(config.logSelector)
    : config.logSelector;

  let instance = null;
  let timeoutHandles = new Map();

  function append(message) {
    if (logElement) {
      logElement.textContent += `\n${message}`;
    }
  }

  function u32(value) {
    return Number(value) >>> 0;
  }

  function readString(ptr, len) {
    const byteOffset = u32(ptr);
    const byteLength = u32(len);
    if (byteLength === 0) {
      return "";
    }

    const bytes = new Uint8Array(instance.exports.memory.buffer, byteOffset, byteLength);
    return decoder.decode(bytes);
  }

  function withWasmString(text, fn) {
    const encoded = encoder.encode(text);
    const ptr = u32(instance.exports.allocBytes(encoded.length));
    if (!ptr && encoded.length !== 0) {
      throw new Error("allocBytes returned 0");
    }

    try {
      if (encoded.length !== 0) {
        const bytes = new Uint8Array(instance.exports.memory.buffer, ptr, encoded.length);
        bytes.set(encoded);
      }
      return fn(ptr, encoded.length);
    } finally {
      instance.exports.freeBytes(ptr, encoded.length);
    }
  }

  function getElementById(id) {
    const element = document.getElementById(id);
    if (!element) {
      append(`bridge warning: missing element #${id}`);
    }
    return element;
  }

  function deliverString(kind, requestId, text) {
    if (typeof instance.exports.bridgeReceiveString !== "function") {
      append("bridge warning: bridgeReceiveString export is missing");
      return;
    }

    withWasmString(text, (ptr, len) => {
      instance.exports.bridgeReceiveString(kind, requestId, ptr, len);
    });
  }

  function deliverFetch(requestId, ok, status, text) {
    if (typeof instance.exports.bridgeReceiveFetch !== "function") {
      append("bridge warning: bridgeReceiveFetch export is missing");
      return;
    }

    withWasmString(text, (ptr, len) => {
      instance.exports.bridgeReceiveFetch(requestId, ok ? 1 : 0, status, ptr, len);
    });
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
        return performance.now();
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
        const storage = kind === 0 ? localStorage : sessionStorage;
        storage.setItem(readString(keyPtr, keyLen), readString(valuePtr, valueLen));
      },
      js_storage_get(kind, requestId, keyPtr, keyLen) {
        const storage = kind === 0 ? localStorage : sessionStorage;
        const key = readString(keyPtr, keyLen);
        deliverString(1, requestId, storage.getItem(key) ?? "");
      },
      js_storage_remove(kind, keyPtr, keyLen) {
        const storage = kind === 0 ? localStorage : sessionStorage;
        storage.removeItem(readString(keyPtr, keyLen));
      },
      js_fetch_text(requestId, methodPtr, methodLen, urlPtr, urlLen, bodyPtr, bodyLen) {
        const method = readString(methodPtr, methodLen);
        const url = readString(urlPtr, urlLen);
        const body = readString(bodyPtr, bodyLen);

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
        const handle = window.setTimeout(() => {
          timeoutHandles.delete(timerId);
          if (typeof instance.exports.bridgeTimerFired === "function") {
            instance.exports.bridgeTimerFired(timerId);
          } else {
            append("bridge warning: bridgeTimerFired export is missing");
          }
        }, delayMs);
        timeoutHandles.set(timerId, handle);
      },
      js_clear_timeout(timerId) {
        const handle = timeoutHandles.get(timerId);
        if (handle !== undefined) {
          clearTimeout(handle);
          timeoutHandles.delete(timerId);
        }
      },
      js_history_push(urlPtr, urlLen) {
        const url = readString(urlPtr, urlLen);
        history.pushState({}, "", url);
      },
      js_set_document_title(titlePtr, titleLen) {
        document.title = readString(titlePtr, titleLen);
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
        const selector = readString(selectorPtr, selectorLen);
        const className = readString(classPtr, classLen);
        for (const element of document.querySelectorAll(selector)) {
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
        const selector = readString(selectorPtr, selectorLen);
        const element = document.querySelector(selector);
        if (element instanceof HTMLElement) {
          element.scrollIntoView({ block: "nearest" });
        }
      },
    },
  };

  const imports = mergeImports(baseImports, config.imports);

  async function instantiate() {
    const response = await fetch(config.wasmUrl);
    if (!response.ok) {
      throw new Error(`fetch failed: ${response.status} ${response.statusText}`);
    }

    const bytes = await response.arrayBuffer();
    const wasmModule = await WebAssembly.instantiate(bytes, imports);
    instance = wasmModule.instance;
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

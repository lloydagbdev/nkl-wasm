import assert from "node:assert/strict";
import fs from "node:fs/promises";

const [corePath, storageTimerPath, domFetchPath] = process.argv.slice(2);

if (!corePath || !storageTimerPath || !domFetchPath) {
  throw new Error("usage: check_selected_bridge_assets.mjs <core.js> <storage-timer.js> <dom-fetch.js>");
}

const originalInstantiate = WebAssembly.instantiate;

async function loadBridge(path) {
  const sourceText = await fs.readFile(path, "utf8");
  const sourceBase64 = Buffer.from(sourceText, "utf8").toString("base64");
  const module = await import(`data:text/javascript;base64,${sourceBase64}`);
  return {
    sourceText,
    createBrowserBridge: module.createBrowserBridge,
  };
}

function setGlobalProperty(name, value) {
  const descriptor = Object.getOwnPropertyDescriptor(globalThis, name);
  if (value === undefined) {
    Reflect.deleteProperty(globalThis, name);
  } else {
    Object.defineProperty(globalThis, name, {
      configurable: true,
      writable: true,
      value,
    });
  }

  return () => {
    if (descriptor) {
      Object.defineProperty(globalThis, name, descriptor);
      return;
    }
    Reflect.deleteProperty(globalThis, name);
  };
}

function setThrowingGlobalProperty(name, message) {
  const descriptor = Object.getOwnPropertyDescriptor(globalThis, name);
  Object.defineProperty(globalThis, name, {
    configurable: true,
    get() {
      throw new Error(message);
    },
  });

  return () => {
    if (descriptor) {
      Object.defineProperty(globalThis, name, descriptor);
      return;
    }
    Reflect.deleteProperty(globalThis, name);
  };
}

async function withPatchedEnvironment(setup, fn) {
  const restore = [];
  const originalWarn = console.warn;
  const warnings = [];

  console.warn = (...args) => {
    warnings.push(args.map(String).join(" "));
  };

  try {
    for (const action of setup) {
      restore.push(action());
    }
    await fn({ warnings });
  } finally {
    console.warn = originalWarn;
    while (restore.length !== 0) {
      const undo = restore.pop();
      undo();
    }
    WebAssembly.instantiate = originalInstantiate;
  }
}

function makeFakeInstance(options = {}) {
  const memory = options.memory ?? new WebAssembly.Memory({ initial: 1 });
  let nextPtr = 64;

  function allocBytes(len) {
    if (len === 0) {
      return 0;
    }

    const ptr = nextPtr;
    nextPtr += len;
    return ptr;
  }

  return {
    exports: {
      memory,
      allocBytes,
      freeBytes() {},
      ...options.exports,
    },
  };
}

function mockInstantiate(instance) {
  WebAssembly.instantiate = async () => ({ instance });
}

function mockFetchOk() {
  return async () => ({
    ok: true,
    status: 200,
    statusText: "OK",
    async arrayBuffer() {
      return new ArrayBuffer(8);
    },
  });
}

async function testCoreProfile() {
  const { sourceText, createBrowserBridge } = await loadBridge(corePath);
  assert.match(sourceText, /createBrowserBridge/);
  assert.doesNotMatch(sourceText, /js_fetch_text/);
  assert.doesNotMatch(sourceText, /js_storage_get/);
  assert.doesNotMatch(sourceText, /js_set_timeout/);
  assert.doesNotMatch(sourceText, /js_history_push/);

  await withPatchedEnvironment([
    () => setGlobalProperty("fetch", mockFetchOk()),
  ], async () => {
    mockInstantiate(makeFakeInstance());
    const bridge = createBrowserBridge({ logSelector: null });
    assert.equal(typeof bridge.imports.env.js_now_ms, "function");
    assert.equal(typeof bridge.imports.env.js_fetch_text, "undefined");
    await bridge.instantiate();
  });
}

async function testStorageTimerProfile() {
  const { sourceText, createBrowserBridge } = await loadBridge(storageTimerPath);
  assert.match(sourceText, /js_storage_get/);
  assert.match(sourceText, /js_set_timeout/);
  assert.match(sourceText, /function deliverString/);
  assert.match(sourceText, /function deliverTimer/);
  assert.doesNotMatch(sourceText, /js_fetch_text/);
  assert.doesNotMatch(sourceText, /js_history_push/);

  await withPatchedEnvironment([
    () => setGlobalProperty("fetch", mockFetchOk()),
    () => setThrowingGlobalProperty("localStorage", "storage denied"),
    () => setGlobalProperty("setTimeout", (fn) => {
      fn();
      return 11;
    }),
    () => setGlobalProperty("clearTimeout", () => {}),
  ], async ({ warnings }) => {
    let receivedString = null;
    let receivedTimer = null;
    const instance = makeFakeInstance({
      exports: {
        bridgeReceiveString(kind, requestId, ptr, len) {
          receivedString = {
            kind,
            requestId,
            text: bridge.readString(ptr, len),
          };
        },
        bridgeTimerFired(timerId) {
          receivedTimer = timerId;
        },
      },
    });
    mockInstantiate(instance);

    const bridge = createBrowserBridge({ logSelector: null });
    await bridge.instantiate();
    bridge.withWasmString("theme", (ptr, len) => {
      bridge.imports.env.js_storage_get(0, 7, ptr, len);
    });
    bridge.imports.env.js_set_timeout(3, 1);

    assert.deepEqual(receivedString, {
      kind: 1,
      requestId: 7,
      text: "",
    });
    assert.equal(receivedTimer, 3);
    assert.ok(warnings.some((warning) => warning.includes("storage access failed")));
  });
}

async function testDomFetchProfile() {
  const { sourceText, createBrowserBridge } = await loadBridge(domFetchPath);
  assert.match(sourceText, /js_set_text_by_id/);
  assert.match(sourceText, /js_fetch_text/);
  assert.match(sourceText, /function deliverString/);
  assert.match(sourceText, /function deliverFetch/);
  assert.doesNotMatch(sourceText, /js_storage_get/);
  assert.doesNotMatch(sourceText, /js_set_timeout/);
  assert.doesNotMatch(sourceText, /js_history_push/);

  await withPatchedEnvironment([
    () => setGlobalProperty("fetch", mockFetchOk()),
    () => setGlobalProperty("document", null),
  ], async ({ warnings }) => {
    mockInstantiate(makeFakeInstance());
    const bridge = createBrowserBridge({ logSelector: null });
    await bridge.instantiate();
    bridge.withWasmString("status", (idPtr, idLen) => {
      bridge.withWasmString("Hello", (textPtr, textLen) => {
        bridge.imports.env.js_set_text_by_id(idPtr, idLen, textPtr, textLen);
      });
    });

    assert.ok(warnings.some((warning) => warning.includes("document is unavailable")));
  });
}

await testCoreProfile();
await testStorageTimerProfile();
await testDomFetchProfile();

console.log("selected bridge asset checks passed");

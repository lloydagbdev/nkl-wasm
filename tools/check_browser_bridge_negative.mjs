import assert from "node:assert/strict";
import fs from "node:fs/promises";

const sourceUrl = new URL("../src/js/browser_bridge.js", import.meta.url);
const sourceText = await fs.readFile(sourceUrl, "utf8");
const sourceBase64 = Buffer.from(sourceText, "utf8").toString("base64");
const { createBrowserBridge } = await import(`data:text/javascript;base64,${sourceBase64}`);

const originalInstantiate = WebAssembly.instantiate;

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
  const warnings = [];
  const errors = [];
  const originalWarn = console.warn;
  const originalError = console.error;

  console.warn = (...args) => {
    warnings.push(args.map(String).join(" "));
  };
  console.error = (...args) => {
    errors.push(args.map(String).join(" "));
  };

  try {
    for (const action of setup) {
      restore.push(action());
    }
    await fn({ warnings, errors });
  } finally {
    console.warn = originalWarn;
    console.error = originalError;
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

async function testLowLevelHelpersRequireInstantiation() {
  const bridge = createBrowserBridge({ logSelector: null });
  assert.throws(() => bridge.readString(0, 1), /not instantiated yet/);
  assert.throws(() => bridge.withWasmString("abc", () => {}), /not instantiated yet/);
}

async function testInstantiateRejectsMissingRequiredExport() {
  await withPatchedEnvironment([
    () => setGlobalProperty("fetch", mockFetchOk()),
  ], async () => {
    const instance = makeFakeInstance({
      exports: {
        memory: new WebAssembly.Memory({ initial: 1 }),
        freeBytes() {},
      },
    });
    delete instance.exports.allocBytes;
    mockInstantiate(instance);

    const bridge = createBrowserBridge({ logSelector: null });
    await assert.rejects(() => bridge.instantiate(), /allocBytes/);
  });
}

async function testStorageGracefulFallback() {
  await withPatchedEnvironment([
    () => setGlobalProperty("fetch", mockFetchOk()),
    () => setThrowingGlobalProperty("localStorage", "storage denied"),
    () => setThrowingGlobalProperty("sessionStorage", "storage denied"),
  ], async ({ warnings }) => {
    let received = null;
    const instance = makeFakeInstance({
      exports: {
        bridgeReceiveString(kind, requestId, ptr, len) {
          received = {
            kind,
            requestId,
            text: bridge.readString(ptr, len),
          };
        },
      },
    });
    mockInstantiate(instance);

    const bridge = createBrowserBridge({ logSelector: null });
    await bridge.instantiate();
    bridge.withWasmString("theme", (ptr, len) => {
      bridge.imports.env.js_storage_get(0, 7, ptr, len);
    });

    assert.deepEqual(received, {
      kind: 1,
      requestId: 7,
      text: "",
    });
    assert.ok(warnings.some((warning) => warning.includes("storage access failed")));
  });
}

async function testOptionalCapabilityWarningsDoNotThrow() {
  await withPatchedEnvironment([
    () => setGlobalProperty("fetch", mockFetchOk()),
    () => setGlobalProperty("document", null),
    () => setGlobalProperty("history", {}),
    () => setGlobalProperty("setTimeout", undefined),
    () => setGlobalProperty("clearTimeout", undefined),
  ], async ({ warnings }) => {
    const bridge = createBrowserBridge({ logSelector: null });
    mockInstantiate(makeFakeInstance());
    await bridge.instantiate();

    bridge.withWasmString("status", (idPtr, idLen) => {
      bridge.withWasmString("Hello", (textPtr, textLen) => {
        bridge.imports.env.js_set_text_by_id(idPtr, idLen, textPtr, textLen);
      });
    });

    bridge.withWasmString("/notes", (ptr, len) => {
      bridge.imports.env.js_history_push(ptr, len);
    });

    bridge.withWasmString("Title", (ptr, len) => {
      bridge.imports.env.js_set_document_title(ptr, len);
    });

    bridge.imports.env.js_set_timeout(3, 10);

    assert.ok(warnings.some((warning) => warning.includes("document is unavailable")));
    assert.ok(warnings.some((warning) => warning.includes("history.pushState is unavailable")));
    assert.ok(warnings.some((warning) => warning.includes("setTimeout is unavailable")));
  });
}

async function testMissingOptionalFetchCallbackOnlyWarns() {
  await withPatchedEnvironment([
    () => setGlobalProperty("fetch", mockFetchOk()),
  ], async ({ warnings }) => {
    const bridge = createBrowserBridge({ logSelector: null });
    mockInstantiate(makeFakeInstance());
    await bridge.instantiate();

    const restoreFetch = setGlobalProperty("fetch", undefined);
    try {
      bridge.withWasmString("GET", (methodPtr, methodLen) => {
        bridge.withWasmString("/data.txt", (urlPtr, urlLen) => {
          bridge.imports.env.js_fetch_text(9, methodPtr, methodLen, urlPtr, urlLen, 0, 0);
        });
      });
    } finally {
      restoreFetch();
    }

    assert.ok(warnings.some((warning) => warning.includes("fetch API is unavailable")));
    assert.ok(warnings.some((warning) => warning.includes("bridgeReceiveFetch export is missing")));
  });
}

async function testNowMsFallback() {
  const originalDateNow = Date.now;
  await withPatchedEnvironment([
    () => setGlobalProperty("performance", {}),
  ], async () => {
    Date.now = () => 4242;
    try {
      const bridge = createBrowserBridge({ logSelector: null });
      assert.equal(bridge.imports.env.js_now_ms(), 4242);
    } finally {
      Date.now = originalDateNow;
    }
  });
}

await testLowLevelHelpersRequireInstantiation();
await testInstantiateRejectsMissingRequiredExport();
await testStorageGracefulFallback();
await testOptionalCapabilityWarningsDoNotThrow();
await testMissingOptionalFetchCallbackOnlyWarns();
await testNowMsFallback();

console.log("browser bridge negative checks passed");

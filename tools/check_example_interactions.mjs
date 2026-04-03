import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const ROOT = path.resolve(import.meta.dirname, "..");
const EXAMPLES_ROOT = path.join(ROOT, "zig-out", "examples");

class FakeClassList {
  constructor(owner) {
    this.owner = owner;
    this.values = new Set();
  }

  toggle(name, force) {
    if (force === undefined) {
      if (this.values.has(name)) {
        this.values.delete(name);
        return false;
      }
      this.values.add(name);
      return true;
    }

    if (force) {
      this.values.add(name);
      return true;
    }

    this.values.delete(name);
    return false;
  }

  contains(name) {
    return this.values.has(name);
  }

  toString() {
    return [...this.values].join(" ");
  }
}

class FakeElement {
  constructor(tagName, options = {}) {
    this.tagName = tagName.toUpperCase();
    this.id = options.id ?? "";
    this.type = options.type ?? "";
    this.textContent = options.textContent ?? "";
    this.innerHTML = options.innerHTML ?? "";
    this.value = options.value ?? "";
    this.disabled = options.disabled ?? false;
    this.checked = options.checked ?? false;
    this.attributes = new Map();
    this.listeners = new Map();
    this.classList = new FakeClassList(this);
  }

  addEventListener(type, handler) {
    const handlers = this.listeners.get(type) ?? [];
    handlers.push(handler);
    this.listeners.set(type, handlers);
  }

  dispatchEvent(event) {
    const handlers = this.listeners.get(event.type) ?? [];
    for (const handler of handlers) {
      handler(event);
    }
  }

  click() {
    this.dispatchEvent({ type: "click" });
  }

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  focus() {}

  scrollIntoView() {}
}

class FakeHTMLElement extends FakeElement {
  constructor(tagName = "div", options = {}) {
    super(tagName, options);
  }
}

class FakeHTMLButtonElement extends FakeHTMLElement {
  constructor(options = {}) {
    super("button", options);
  }
}

class FakeHTMLInputElement extends FakeHTMLElement {
  constructor(options = {}) {
    super("input", options);
  }
}

class FakeDocument {
  constructor(elements, title = "") {
    this.title = title;
    this.elements = new Map();
    for (const element of elements) {
      if (element.id) {
        this.elements.set(element.id, element);
      }
    }
  }

  getElementById(id) {
    return this.elements.get(id) ?? null;
  }

  querySelector(selector) {
    if (selector.startsWith("#")) {
      return this.getElementById(selector.slice(1));
    }

    if (selector.startsWith(".")) {
      for (const element of this.elements.values()) {
        if (element.classList.contains(selector.slice(1))) {
          return element;
        }
      }
    }

    return null;
  }

  querySelectorAll(selector) {
    if (selector.startsWith("#")) {
      const element = this.getElementById(selector.slice(1));
      return element ? [element] : [];
    }

    if (selector.startsWith(".")) {
      const matches = [];
      for (const element of this.elements.values()) {
        if (element.classList.contains(selector.slice(1))) {
          matches.push(element);
        }
      }
      return matches;
    }

    return [];
  }
}

class FakeWindow {
  constructor(document) {
    this.document = document;
    this.listeners = new Map();
    this.location = { search: "" };
    this.history = {
      pushState: (_state, _title, url) => {
        this.location.search = String(url);
      },
    };
  }

  addEventListener(type, handler) {
    const handlers = this.listeners.get(type) ?? [];
    handlers.push(handler);
    this.listeners.set(type, handlers);
  }

  dispatchEvent(event) {
    const handlers = this.listeners.get(event.type) ?? [];
    for (const handler of handlers) {
      handler(event);
    }
  }
}

function createExampleDocument(name) {
  switch (name) {
    case "echo":
      return new FakeDocument([
        new FakeHTMLInputElement({ id: "echo-input", type: "text", value: "" }),
        new FakeHTMLButtonElement({ id: "echo-button", type: "button" }),
        new FakeHTMLButtonElement({ id: "clear-button", type: "button" }),
        new FakeHTMLElement("p", { id: "status", textContent: "Booting…" }),
        new FakeHTMLElement("pre", { id: "echo-output", textContent: "" }),
      ], "nkl-wasm echo example");
    case "fetch":
      return new FakeDocument([
        new FakeHTMLButtonElement({ id: "fetch-button", type: "button" }),
        new FakeHTMLButtonElement({ id: "clear-button", type: "button" }),
        new FakeHTMLElement("p", { id: "status", textContent: "Booting…" }),
        new FakeHTMLElement("pre", { id: "fetch-output", textContent: "" }),
      ], "nkl-wasm fetch example");
    case "ssr-enhance":
      return new FakeDocument([
        new FakeHTMLInputElement({ id: "initial-count", type: "hidden", value: "3" }),
        new FakeHTMLElement("strong", { id: "count-value", textContent: "3" }),
        new FakeHTMLElement("p", { id: "wasm-status", textContent: "Wasm not booted yet." }),
        new FakeHTMLButtonElement({ id: "increment-button", type: "button", disabled: true }),
      ], "nkl-wasm SSR + Wasm reference");
    case "csr":
      return new FakeDocument([
        new FakeHTMLElement("p", { id: "status", textContent: "Booting…" }),
        new FakeHTMLInputElement({ id: "filter-input", type: "text", value: "", disabled: true }),
        new FakeHTMLElement("div", { id: "items", textContent: "No items yet." }),
      ], "nkl-wasm CSR reference");
    case "spa-like":
      return new FakeDocument([
        new FakeHTMLButtonElement({ id: "nav-home", type: "button" }),
        new FakeHTMLButtonElement({ id: "nav-about", type: "button" }),
        new FakeHTMLButtonElement({ id: "nav-notes", type: "button" }),
        new FakeHTMLElement("p", { id: "status", textContent: "Booting…" }),
        new FakeHTMLElement("div", { id: "view-content", textContent: "No view rendered yet." }),
      ], "nkl-wasm SPA-like reference");
    default:
      throw new Error(`unknown example ${name}`);
  }
}

function makeFetch(exampleDir) {
  return async (url) => {
    const raw = String(url);
    const relative = raw.startsWith("./") ? raw.slice(2) : raw;
    const filePath = path.join(exampleDir, relative);

    try {
      const data = await fs.readFile(filePath);
      return {
        ok: true,
        status: 200,
        statusText: "OK",
        async arrayBuffer() {
          return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
        },
        async text() {
          return data.toString("utf8");
        },
      };
    } catch {
      return {
        ok: false,
        status: 404,
        statusText: "Not Found",
        async arrayBuffer() {
          return new ArrayBuffer(0);
        },
        async text() {
          return "";
        },
      };
    }
  };
}

async function flush() {
  await new Promise((resolve) => setTimeout(resolve, 0));
}

async function waitFor(predicate, message) {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    if (predicate()) {
      return;
    }
    await flush();
  }

  throw new Error(message);
}

async function withExampleEnvironment(name, fn) {
  const exampleDir = path.join(EXAMPLES_ROOT, name);
  const document = createExampleDocument(name);
  const window = new FakeWindow(document);

  const previous = {
    document: globalThis.document,
    window: globalThis.window,
    history: globalThis.history,
    location: globalThis.location,
    fetch: globalThis.fetch,
    HTMLElement: globalThis.HTMLElement,
    HTMLButtonElement: globalThis.HTMLButtonElement,
    HTMLInputElement: globalThis.HTMLInputElement,
    setTimeout: globalThis.setTimeout,
    clearTimeout: globalThis.clearTimeout,
    performance: globalThis.performance,
  };

  globalThis.document = document;
  globalThis.window = window;
  globalThis.history = window.history;
  globalThis.location = window.location;
  globalThis.fetch = makeFetch(exampleDir);
  globalThis.HTMLElement = FakeHTMLElement;
  globalThis.HTMLButtonElement = FakeHTMLButtonElement;
  globalThis.HTMLInputElement = FakeHTMLInputElement;
  globalThis.setTimeout = setTimeout;
  globalThis.clearTimeout = clearTimeout;

  try {
    const appUrl = pathToFileURL(path.join(exampleDir, "app.js")).href + `?t=${Date.now()}-${Math.random()}`;
    await import(appUrl);
    await flush();
    await fn({ document, window });
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) {
        Reflect.deleteProperty(globalThis, key);
      } else {
        globalThis[key] = value;
      }
    }
  }
}

async function testEcho() {
  await withExampleEnvironment("echo", async ({ document }) => {
    await waitFor(
      () => document.getElementById("status").textContent === "Ready.",
      "echo example did not boot",
    );

    const input = document.getElementById("echo-input");
    input.value = "hello";
    document.getElementById("echo-button").click();
    await waitFor(
      () => /echo 1: hello/.test(document.getElementById("echo-output").textContent),
      "echo example did not handle click interaction",
    );

    assert.match(document.getElementById("echo-output").textContent, /echo 1: hello/);
    assert.match(document.getElementById("status").textContent, /Last message length: 5/);
    assert.equal(input.value, "");
  });
}

async function testFetch() {
  await withExampleEnvironment("fetch", async ({ document }) => {
    await waitFor(
      () => document.getElementById("status").textContent === "Ready to fetch.",
      "fetch example did not boot",
    );

    document.getElementById("fetch-button").click();
    await waitFor(
      () => /Fetched \d+ bytes with status 200/.test(document.getElementById("status").textContent),
      "fetch example did not complete fetch interaction",
    );

    assert.match(document.getElementById("fetch-output").textContent, /nkl-wasm fetch example payload/);
    assert.match(document.getElementById("status").textContent, /Fetched \d+ bytes with status 200/);

    document.getElementById("clear-button").click();
    await flush();

    assert.equal(document.getElementById("fetch-output").textContent, "");
    assert.equal(document.getElementById("status").textContent, "Cleared.");
  });
}

async function testSsrEnhance() {
  await withExampleEnvironment("ssr-enhance", async ({ document }) => {
    await waitFor(
      () => /Wasm active/.test(document.getElementById("wasm-status").textContent),
      "ssr-enhance example did not boot",
    );
    assert.equal(document.getElementById("count-value").textContent, "3");
    assert.equal(document.getElementById("increment-button").disabled, false);
    assert.match(document.getElementById("wasm-status").textContent, /Wasm active/);

    document.getElementById("increment-button").click();
    await waitFor(
      () => document.getElementById("count-value").textContent === "4",
      "ssr-enhance example did not increment",
    );

    assert.equal(document.getElementById("count-value").textContent, "4");
  });
}

async function testCsr() {
  await withExampleEnvironment("csr", async ({ document }) => {
    await waitFor(
      () => document.getElementById("filter-input").disabled === false,
      "csr example did not finish boot fetch",
    );

    const filterInput = document.getElementById("filter-input");
    assert.equal(filterInput.disabled, false);
    assert.match(document.getElementById("items").innerHTML, /Alpha item/);
    assert.match(document.getElementById("items").innerHTML, /Beta item/);

    filterInput.value = "beta";
    filterInput.dispatchEvent({ type: "input" });
    await waitFor(
      () => /Showing 1 of 3 items/.test(document.getElementById("status").textContent),
      "csr example did not apply filter interaction",
    );

    assert.doesNotMatch(document.getElementById("items").innerHTML, /Alpha item/);
    assert.match(document.getElementById("items").innerHTML, /Beta item/);
    assert.match(document.getElementById("status").textContent, /Showing 1 of 3 items/);
  });
}

async function testSpaLike() {
  await withExampleEnvironment("spa-like", async ({ document, window }) => {
    await waitFor(
      () => /SPA-like view active: home/.test(document.getElementById("status").textContent),
      "spa-like example did not boot",
    );

    assert.match(document.getElementById("status").textContent, /SPA-like view active: home/);
    assert.equal(document.title, "nkl-wasm SPA-like demo: Home");
    assert.equal(document.getElementById("nav-home").classList.contains("is-active"), true);

    document.getElementById("nav-about").click();
    await waitFor(
      () => document.title === "nkl-wasm SPA-like demo: About",
      "spa-like example did not navigate to about",
    );

    assert.equal(window.location.search, "?view=about");
    assert.equal(document.title, "nkl-wasm SPA-like demo: About");
    assert.equal(document.getElementById("nav-about").classList.contains("is-active"), true);
    assert.match(document.getElementById("view-content").innerHTML, /<h2>About<\/h2>/);

    window.location.search = "?view=notes";
    window.dispatchEvent({ type: "popstate" });
    await waitFor(
      () => document.title === "nkl-wasm SPA-like demo: Notes",
      "spa-like example did not react to popstate",
    );

    assert.equal(document.title, "nkl-wasm SPA-like demo: Notes");
    assert.equal(document.getElementById("nav-notes").classList.contains("is-active"), true);
    assert.match(document.getElementById("view-content").innerHTML, /No framework router/);
  });
}

await testEcho();
await testFetch();
await testSsrEnhance();
await testCsr();
await testSpaLike();

console.log("example interaction checks passed");

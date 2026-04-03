import { createBrowserBridge } from "./browser_bridge.js";

const bridge = createBrowserBridge({
  wasmUrl: "./app.wasm",
  logSelector: null,
});

async function main() {
  const instance = await bridge.instantiate();

  if (typeof instance.exports.start === "function") {
    instance.exports.start();
  }

  const fetchButton = document.getElementById("fetch-button");
  const clearButton = document.getElementById("clear-button");

  if (fetchButton instanceof HTMLButtonElement && typeof instance.exports.onFetchClick === "function") {
    fetchButton.addEventListener("click", () => {
      instance.exports.onFetchClick();
    });
  }

  if (clearButton instanceof HTMLButtonElement && typeof instance.exports.onClearClick === "function") {
    clearButton.addEventListener("click", () => {
      instance.exports.onClearClick();
    });
  }
}

main().catch((error) => {
  console.error(error);
  const status = document.getElementById("status");
  if (status) {
    status.textContent = "Wasm failed to start. Check the browser console.";
  }
});

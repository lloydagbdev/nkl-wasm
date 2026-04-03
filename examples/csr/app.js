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

  const filterInput = document.getElementById("filter-input");
  if (filterInput instanceof HTMLInputElement && typeof instance.exports.onFilterInput === "function") {
    filterInput.addEventListener("input", () => {
      instance.exports.onFilterInput();
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

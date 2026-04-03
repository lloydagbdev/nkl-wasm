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

  const incrementButton = document.getElementById("increment-button");
  if (incrementButton instanceof HTMLButtonElement && typeof instance.exports.onIncrementClick === "function") {
    incrementButton.addEventListener("click", () => {
      instance.exports.onIncrementClick();
    });
  }
}

main().catch((error) => {
  console.error(error);
  const status = document.getElementById("wasm-status");
  if (status) {
    status.textContent = "Wasm failed to start. Check the browser console.";
  }
});

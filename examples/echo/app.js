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

  const echoButton = document.getElementById("echo-button");
  const clearButton = document.getElementById("clear-button");
  const input = document.getElementById("echo-input");

  if (echoButton instanceof HTMLButtonElement && typeof instance.exports.onEchoSubmit === "function") {
    echoButton.addEventListener("click", () => {
      instance.exports.onEchoSubmit();
    });
  }

  if (clearButton instanceof HTMLButtonElement && typeof instance.exports.onClearLog === "function") {
    clearButton.addEventListener("click", () => {
      instance.exports.onClearLog();
    });
  }

  if (input instanceof HTMLInputElement && typeof instance.exports.onEchoSubmit === "function") {
    input.addEventListener("keydown", (event) => {
      if (event.key !== "Enter") return;
      event.preventDefault();
      instance.exports.onEchoSubmit();
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

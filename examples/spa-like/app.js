import { createBrowserBridge } from "./browser_bridge.js";

const bridge = createBrowserBridge({
  wasmUrl: "./app.wasm",
  logSelector: null,
});

function sendLocation(instance) {
  if (typeof instance.exports.onLocationChange !== "function") {
    return;
  }
  bridge.withWasmString(window.location.search, (ptr, len) => {
    instance.exports.onLocationChange(ptr, len);
  });
}

async function main() {
  const instance = await bridge.instantiate();

  if (typeof instance.exports.start === "function") {
    instance.exports.start();
  }

  const homeButton = document.getElementById("nav-home");
  const aboutButton = document.getElementById("nav-about");
  const notesButton = document.getElementById("nav-notes");

  if (homeButton instanceof HTMLButtonElement && typeof instance.exports.onNavigateHome === "function") {
    homeButton.addEventListener("click", () => {
      instance.exports.onNavigateHome();
    });
  }

  if (aboutButton instanceof HTMLButtonElement && typeof instance.exports.onNavigateAbout === "function") {
    aboutButton.addEventListener("click", () => {
      instance.exports.onNavigateAbout();
    });
  }

  if (notesButton instanceof HTMLButtonElement && typeof instance.exports.onNavigateNotes === "function") {
    notesButton.addEventListener("click", () => {
      instance.exports.onNavigateNotes();
    });
  }

  window.addEventListener("popstate", () => {
    sendLocation(instance);
  });

  sendLocation(instance);
}

main().catch((error) => {
  console.error(error);
  const status = document.getElementById("status");
  if (status) {
    status.textContent = "Wasm failed to start. Check the browser console.";
  }
});

(() => {
  "use strict";

  const payloadView = document.querySelector("#payload-view");
  const emptyView = document.querySelector("#empty-view");
  const errorView = document.querySelector("#error-view");
  const textArea = document.querySelector("#copy-text");
  const copyButton = document.querySelector("#copy-button");
  const status = document.querySelector("#status");

  function decodePayload(hash) {
    if (!hash.startsWith("#v1.")) throw new Error("Unsupported payload");
    let encoded = hash.slice(4).replace(/-/g, "+").replace(/_/g, "/");
    encoded += "=".repeat((4 - encoded.length % 4) % 4);
    const binary = atob(encoded);
    const bytes = Uint8Array.from(binary, character => character.charCodeAt(0));
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  }

  function fallbackCopy() {
    textArea.focus();
    textArea.select();
    textArea.setSelectionRange(0, textArea.value.length);
    return document.execCommand("copy");
  }

  async function copyText() {
    let copied = false;
    try {
      await navigator.clipboard.writeText(textArea.value);
      copied = true;
    } catch (_) {
      copied = fallbackCopy();
    }

    if (copied) {
      copyButton.classList.add("copied");
      copyButton.querySelector(".button-label").textContent = "Copied";
      status.textContent = "Ready to paste anywhere.";
      setTimeout(() => {
        copyButton.classList.remove("copied");
        copyButton.querySelector(".button-label").textContent = "Copy text";
      }, 2200);
    } else {
      status.textContent = "Press and hold the text, then choose Copy.";
      textArea.focus();
      textArea.select();
    }
  }

  if (!location.hash) {
    emptyView.hidden = false;
    return;
  }

  try {
    textArea.value = decodePayload(location.hash);
    payloadView.hidden = false;
    history.replaceState(null, "", location.pathname + location.search);
    copyButton.addEventListener("click", copyText);
  } catch (_) {
    errorView.hidden = false;
  }
})();

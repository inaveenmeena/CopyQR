(() => {
  "use strict";

  const payloadView = document.querySelector("#payload-view");
  const emptyView = document.querySelector("#empty-view");
  const errorView = document.querySelector("#error-view");
  const textArea = document.querySelector("#copy-text");
  const copyButton = document.querySelector("#copy-button");
  const status = document.querySelector("#status");

  function base64URLBytes(encoded) {
    encoded = encoded.replace(/-/g, "+").replace(/_/g, "/");
    encoded += "=".repeat((4 - encoded.length % 4) % 4);
    const binary = atob(encoded);
    return Uint8Array.from(binary, character => character.charCodeAt(0));
  }

  async function inflateRaw(bytes) {
    if (!("DecompressionStream" in window)) throw new Error("Compression is not supported by this browser");
    const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("deflate-raw"));
    return new Uint8Array(await new Response(stream).arrayBuffer());
  }

  async function decodePayload(hash) {
    const decoder = new TextDecoder("utf-8", { fatal: true });
    if (hash.startsWith("#v1.")) return decoder.decode(base64URLBytes(hash.slice(4)));
    if (hash.startsWith("#v2.")) return decoder.decode(await inflateRaw(base64URLBytes(hash.slice(4))));
    throw new Error("Unsupported payload");
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
      // Android and other supporting browsers vibrate here. WebKit on iPhone
      // currently exposes no web API for custom Taptic Engine feedback.
      if (navigator.vibrate) navigator.vibrate(35);
      copyButton.classList.add("copied");
      copyButton.querySelector(".button-label").textContent = "Copied";
      status.textContent = "Ready to paste anywhere.";
      document.body.classList.add("just-copied");
      setTimeout(() => {
        copyButton.classList.remove("copied");
        copyButton.querySelector(".button-label").textContent = "Copy text";
        document.body.classList.remove("just-copied");
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

  (async () => {
    try {
      textArea.value = await decodePayload(location.hash);
      payloadView.hidden = false;
      history.replaceState(null, "", location.pathname + location.search);
      copyButton.addEventListener("click", copyText);
    } catch (_) {
      errorView.hidden = false;
    }
  })();
})();

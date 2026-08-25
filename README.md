# CopyQR v1.0.2

A tiny, native macOS menu-bar app that turns selected text into a QR code. Web links open directly; ordinary text opens a private, one-tap Copy page on your phone.

See [FUNCTIONALITY.md](FUNCTIONALITY.md) for the complete v1 feature set, permissions, and current limitations.

## Use

1. Open `dist/CopyQR.app`.
2. Press **Control-Q** once and allow CopyQR under **System Settings → Privacy & Security → Accessibility**.
3. Select text in any app and press **Control-Q**.
4. Scan the QR code with your phone. For ordinary text, tap **Copy text** on the receiver page.

Accessibility permission lets CopyQR read the text you actively select when its global shortcut is pressed. You can also copy text normally, click the QR icon in the macOS menu bar, and choose **Show Clipboard as QR**.

CopyQR has no analytics and never uploads selected text. Ordinary text is encoded after `#` in the receiver URL; URL fragments are not sent in HTTP requests. The static receiver contains no accounts, storage, cookies, or third-party scripts.

The encoded receiver URL must still fit in one QR code. v1.0.2 accepts at most **2,143 UTF-8 text bytes** for ordinary text. That is roughly 350 English words, or commonly 2–5 medium paragraphs. Non-Latin scripts and emoji use more bytes, so their character capacity is lower. For the most reliable phone scanning, shorter text works best.

## Build

```sh
chmod +x build.sh
./build.sh
```

The build uses only Apple frameworks and the Clang compiler included with macOS Command Line Tools.

# CopyQR v1.0.2

A tiny, native macOS menu-bar app that turns selected text into a QR code. Web links open directly; ordinary text opens a private, one-tap Copy page on your phone.

See [FUNCTIONALITY.md](FUNCTIONALITY.md) for the complete v1 feature set, permissions, and current limitations.

## Use

1. Open `dist/CopyQR.app`.
2. Select text in any app.
3. Press **Shift-Command-R**, or right-click and choose **Services → Show Selection as QR**.
4. Scan the QR code with your phone. For ordinary text, tap **Copy text** on the receiver page.

CopyQR uses the native macOS Services system and does not require Accessibility permission. You can also copy text normally, click the QR icon in the macOS menu bar, and choose **Show Clipboard as QR**.

CopyQR has no analytics and never uploads selected text. Ordinary text is encoded after `#` in the receiver URL; URL fragments are not sent in HTTP requests. The static receiver contains no accounts, storage, cookies, or third-party scripts.

The encoded receiver URL must still fit in one QR code. v1.0.2 accepts at most **2,143 UTF-8 text bytes** for ordinary text. That is roughly 350 English words, or commonly 2–5 medium paragraphs. Non-Latin scripts and emoji use more bytes, so their character capacity is lower. For the most reliable phone scanning, shorter text works best.

## Build

```sh
chmod +x build.sh
./build.sh
```

The build uses only Apple frameworks and the Clang compiler included with macOS Command Line Tools.

# CopyQR v1.0.1

A tiny, native macOS menu-bar app that turns selected text into a QR code. Web links open directly; ordinary text opens a private, one-tap Copy page on your phone.

See [FUNCTIONALITY.md](FUNCTIONALITY.md) for the complete v1 feature set, permissions, and current limitations.

## Use

1. Open `dist/CopyQR.app`.
2. Select text in any app.
3. Press **Shift-Command-Q**.
4. The first time, allow CopyQR under **System Settings → Privacy & Security → Accessibility**.
5. Scan the QR code with your phone. For ordinary text, tap **Copy text** on the receiver page.

You can also copy text normally, click the QR icon in the macOS menu bar, and choose **Show Clipboard as QR**. That menu action does not require Accessibility permission.

CopyQR has no analytics and never uploads selected text. Ordinary text is encoded after `#` in the receiver URL; URL fragments are not sent in HTTP requests. The static receiver contains no accounts, storage, cookies, or third-party scripts.

The encoded receiver URL must still fit in one QR code. Base64URL encoding adds some overhead, so ordinary text selections of roughly 2 KB or less are the practical v1.0.1 range. For the most reliable phone scanning, shorter text works best.

## Build

```sh
chmod +x build.sh
./build.sh
```

The build uses only Apple frameworks and the Clang compiler included with macOS Command Line Tools.

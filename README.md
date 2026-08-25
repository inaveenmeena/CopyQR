# CopyQR v1

A tiny, native macOS menu-bar app that turns clipboard text into a QR code.

See [FUNCTIONALITY.md](FUNCTIONALITY.md) for the complete v1 feature set, permissions, and current limitations.

## Use

1. Open `dist/CopyQR.app`.
2. Select text in any app.
3. Press **Shift-Command-Q**.
4. The first time, allow CopyQR under **System Settings → Privacy & Security → Accessibility**.
5. Scan the QR code with your phone.

You can also copy text normally, click the QR icon in the macOS menu bar, and choose **Show Clipboard as QR**. That menu action does not require Accessibility permission.

CopyQR is offline, has no analytics, and sends nothing over the network. Version 1 supports one QR code with up to 2,900 UTF-8 bytes. For the most reliable phone scanning, shorter text works best.

## Build

```sh
chmod +x build.sh
./build.sh
```

The build uses only Apple frameworks and the Clang compiler included with macOS Command Line Tools.

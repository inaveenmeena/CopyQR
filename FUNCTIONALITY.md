# CopyQR v1 functionality

CopyQR v1 is a small, native macOS menu-bar utility for moving selected text from a Mac to a phone through a QR code.

## Main workflow

1. Select text in any macOS application.
2. Press **Shift-Command-Q**.
3. CopyQR reads the selected text and displays it as a QR code.
4. Scan the QR code using a phone camera.

## Included functionality

- Runs as a menu-bar utility without a Dock icon.
- Reads the current text selection through the macOS Accessibility API.
- Registers **Shift-Command-Q** as a system-wide shortcut.
- Includes a clipboard-based fallback in the menu-bar menu for applications that do not expose selected text.
- Generates QR codes locally with Apple's Core Image framework.
- Keeps the QR window above ordinary windows and available across Spaces.
- Works entirely offline and includes no accounts, analytics, tracking, uploads, or third-party dependencies.
- Supports up to 2,900 UTF-8 bytes in one QR code.
- Provides a native Apple-silicon macOS application bundle.

## Permissions

CopyQR requests macOS Accessibility permission so it can read text selected in another application. Clipboard fallback mode does not require this permission.

## Current v1 limitations

- Plain-text QR handling depends on the phone's camera application. The iPhone Camera may offer to search plain text instead of copying it.
- Only one QR frame is supported; oversized text is rejected.
- The included binary is built for Apple-silicon Macs.
- The app is ad-hoc signed for local use and is not notarized through the Apple Developer Program.

## Planned direction

A future version may encode text inside a private HTTPS receiver link so an iPhone opens a minimal page with a dedicated **Copy** button, without requiring the Mac and phone to share a Wi-Fi network.

# CopyQR v1.0.1 functionality

CopyQR v1 is a small, native macOS menu-bar utility for moving selected text from a Mac to a phone through a QR code.

## Main workflow

1. Select text in any macOS application.
2. Press **Shift-Command-Q**.
3. CopyQR reads the selected text and detects whether it is a web link or ordinary text.
4. Web links are encoded directly. Ordinary text is Base64URL-encoded inside the fragment of the CopyQR receiver URL.
5. Scan the QR code using a phone camera. For ordinary text, tap **Copy text** on the receiver page.

## Included functionality

- Runs as a menu-bar utility without a Dock icon.
- Reads the current text selection through the macOS Accessibility API.
- Registers **Shift-Command-Q** as a system-wide shortcut.
- Includes a clipboard-based fallback in the menu-bar menu for applications that do not expose selected text.
- Generates QR codes locally with Apple's Core Image framework.
- Keeps the QR window above ordinary windows and available across Spaces.
- Works entirely offline and includes no accounts, analytics, tracking, uploads, or third-party dependencies.
- Keeps web links opening directly on scan.
- Gives ordinary text a dedicated HTTPS receiver with one-tap copying on iPhone.
- Keeps text inside the URL fragment, which is not sent to the receiver host in an HTTP request.
- Removes the fragment from the visible browser URL after decoding.
- Supports QR payloads up to 2,900 bytes; ordinary text capacity is lower because URL encoding adds overhead.
- Provides a native Apple-silicon macOS application bundle.

## Permissions

CopyQR requests macOS Accessibility permission so it can read text selected in another application. Clipboard fallback mode does not require this permission.

## Current v1 limitations

- Only one QR frame is supported; oversized text is rejected.
- The included binary is built for Apple-silicon Macs.
- The app is ad-hoc signed for local use and is not notarized through the Apple Developer Program.

## Planned direction

A future version may use an encrypted, expiring relay for text too large to fit inside one QR code.

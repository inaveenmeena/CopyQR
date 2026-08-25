# CopyQR v1.0.2 functionality

CopyQR v1 is a small, native macOS menu-bar utility for moving selected text from a Mac to a phone through a QR code.

## Main workflow

1. Select text in any macOS application.
2. Press **Shift-Command-R**, or use **Services → Show Selection as QR** from the context menu.
3. macOS passes the selection to CopyQR through its native Services system; Accessibility permission is not required.
4. CopyQR detects whether it is a web link or ordinary text.
5. Web links are encoded directly. Ordinary text is Base64URL-encoded inside the fragment of the CopyQR receiver URL.
6. Scan the QR code using a phone camera. For ordinary text, tap **Copy text** on the receiver page.

## Included functionality

- Runs as a menu-bar utility without a Dock icon.
- Receives selected text through the native macOS Services system.
- Provides **Shift-Command-R** as the service shortcut.
- Adds **Show Selection as QR** to the Services/right-click menu.
- Includes a clipboard-based fallback for applications that do not support text Services.
- Generates QR codes locally with Apple's Core Image framework.
- Keeps the QR window above ordinary windows and available across Spaces.
- Works entirely offline and includes no accounts, analytics, tracking, uploads, or third-party dependencies.
- Keeps web links opening directly on scan.
- Gives ordinary text a dedicated HTTPS receiver with one-tap copying on iPhone.
- Keeps text inside the URL fragment, which is not sent to the receiver host in an HTTP request.
- Removes the fragment from the visible browser URL after decoding.
- Supports QR payloads up to 2,900 bytes and exactly 2,143 UTF-8 source bytes for ordinary text with the current receiver URL.
- Provides a native Apple-silicon macOS application bundle.

## Permissions

CopyQR does not require Accessibility permission. The foreground application provides selected text through the user-invoked macOS Services system.

## Current v1 limitations

- Only one QR frame is supported; oversized text is rejected.
- The included binary is built for Apple-silicon Macs.
- The app is ad-hoc signed for local use and is not notarized through the Apple Developer Program.

## Planned direction

A future version may use an encrypted, expiring relay for text too large to fit inside one QR code.

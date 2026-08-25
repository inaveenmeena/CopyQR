# CopyQR v1.0.3 functionality

CopyQR v1 is a small, native macOS menu-bar utility for moving selected text from a Mac to a phone through a QR code.

## Main workflow

1. Select text in any macOS application.
2. Press **Control-Q**.
3. CopyQR reads the active selection using the one-time macOS Accessibility permission.
4. CopyQR detects whether it is a web link or ordinary text.
5. Web links are encoded directly. Ordinary text uses whichever is smaller: plain UTF-8 or maximum-level raw DEFLATE, Base64URL-encoded inside the fragment of the CopyQR receiver URL.
6. Scan the QR code using a phone camera. For ordinary text, tap **Copy text** on the receiver page.

## Included functionality

- Runs as a menu-bar utility without a Dock icon.
- Registers **Control-Q** as a global shortcut.
- Reads selected text directly through macOS Accessibility APIs without replacing the clipboard.
- Uses the proven v1.0.0 system-wide Accessibility selection lookup without clipboard access.
- Preserves every character of the selected plain text, including paragraphs, blank lines, spaces, tabs, indentation, and code layout.
- Tests multiple maximum-level DEFLATE strategies and uses the smallest QR payload, while avoiding compression when it would increase size.
- Shows current QR bytes, the 2,900-byte limit, percentage used, and original text bytes.
- Explains the excess bytes, approximate reduction, and suggested chunk count for oversized selections.
- Shows live Accessibility readiness in the menu and provides a one-click link to the correct Settings page.
- Offers optional Launch at Login using macOS Service Management.
- Includes a clipboard-based fallback for applications that do not expose selected text through Accessibility.
- Generates QR codes locally with Apple's Core Image framework.
- Keeps the QR window above ordinary windows and available across Spaces.
- Works entirely offline and includes no accounts, analytics, tracking, uploads, or third-party dependencies.
- Keeps web links opening directly on scan.
- Gives ordinary text a dedicated HTTPS receiver with one-tap copying on iPhone.
- Keeps text inside the URL fragment, which is not sent to the receiver host in an HTTP request.
- Removes the fragment from the visible browser URL after decoding.
- Supports QR payloads up to 2,900 bytes; source-text capacity varies with compressibility.
- Uses a versioned, cross-platform payload format: `v1` is plain UTF-8 and `v2` is raw DEFLATE. Both are Base64URL encoded.
- Gives clear animated confirmation after copying on the receiver and requests a short vibration on browsers that support web haptics. iPhone Safari currently provides visual confirmation only because WebKit does not expose custom device vibration.
- Provides a native Apple-silicon macOS application bundle.

## Permissions

CopyQR requires Accessibility permission to read the active selection when **Control-Q** is pressed. Release builds use a stable private self-signed code identity so macOS can retain this permission when the app is updated.

## Current v1 limitations

- Only one QR frame is supported; oversized text is rejected.
- The included binary is built for Apple-silicon Macs.
- The app uses a stable self-signed release identity but is not Apple-notarized, so public downloads still require the user to approve opening an unidentified developer app.
- Compressed `v2` receiver links require a browser with raw-DEFLATE Compression Streams support (Safari/iOS 16.4 or newer, or a comparable modern browser).

## Planned direction

A future version may use an encrypted, expiring relay for text too large to fit inside one QR code. Images are intentionally deferred to a later release because they require that relay.

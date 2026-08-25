# CopyQR v1.0.3e experimental functionality

CopyQR v1 is a small, native macOS menu-bar utility for moving selected text from a Mac to a phone through a QR code.

## Main workflow

1. Select text in any macOS application.
2. Press **Control-Q**.
3. CopyQR reads the active selection using the one-time macOS Accessibility permission.
4. CopyQR detects whether it is a web link or ordinary text.
5. Web links are encoded directly. For ordinary text, CopyQR embeds a miniature self-contained HTML receiver plus the smaller of plain UTF-8 or maximum-level raw DEFLATE data.
6. Scan the QR code using a phone camera. If iOS accepts the experimental `data:` URL, tap **Copy text** on the entirely offline page.

## Included functionality

- Runs as a menu-bar utility without a Dock icon.
- Registers **Control-Q** as a global shortcut.
- Reads selected text directly through macOS Accessibility APIs without replacing the clipboard whenever the source app exposes it.
- Remembers the last active non-CopyQR application and reads its focused selection directly, with a system-wide Accessibility lookup as fallback. This prevents CopyQR's own QR window from hiding the source selection.
- Searches the focused browser window for nested web-area selections and supports WebKit/Chromium text-marker ranges used by Safari and Chrome.
- When any app withholds its selection, asks that app to copy it, generates the QR, and leaves that text as the current clipboard value.
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
- Embeds the receiver page and selected text together in a self-contained `data:text/html` URL, with no web host involved.
- Supports QR payloads up to 2,900 bytes; source-text capacity varies with compressibility.
- Uses an experimental payload format: `1.` is plain UTF-8 and `2.` is raw DEFLATE. Both are Base64URL encoded after the self-contained page fragment.
- Provides a native Apple-silicon macOS application bundle.

## Permissions

CopyQR requires Accessibility permission to read the active selection when **Control-Q** is pressed. Release builds use a stable private self-signed code identity so macOS can retain this permission when the app is updated.

The universal fallback performs a normal copy. Clipboard managers such as Maccy will record that copied text, which can be removed from their history manually.

## Current v1 limitations

- Only one QR frame is supported; oversized text is rejected.
- The included binary is built for Apple-silicon Macs.
- The app uses a stable self-signed release identity but is not Apple-notarized, so public downloads still require the user to approve opening an unidentified developer app.
- Compressed `2.` payloads require a browser with raw-DEFLATE Compression Streams support (Safari/iOS 16.4 or newer, or a comparable modern browser).
- iPhone Camera may refuse to open `data:` URLs or Safari may restrict clipboard operations for opaque-origin pages; v1.0.3e exists specifically to test this behavior.
- Embedding the receiver code reduces the amount of selected text that fits in one QR compared with stable v1.0.3.

## Planned direction

A future version may use an encrypted, expiring relay for text too large to fit inside one QR code. Images are intentionally deferred to a later release because they require that relay.

# Changelog

## 1.0.2

- Replace Accessibility-based selection capture with a native macOS Service.
- Preserve Shift-Command-Q as the service keyboard shortcut.
- Add **Show Selection as QR** to the macOS Services/right-click menu.
- Stop requesting Accessibility permission across app updates.
- Update the receiver and repository identity from `inaveengehlot` to `inaveenmeena`.
- Add a **Designed by Naveen Meena · @inaveenmeena** credit to the receiver.
- Document the exact single-QR text capacity.

## 1.0.1

- Detect web links and keep their native open-on-scan behavior.
- Wrap ordinary text in a private URL fragment handled by the CopyQR receiver.
- Add a polished, touch-first receiver page with a large one-tap Copy button.
- Remove the fragment from the visible browser URL immediately after decoding.
- Add an iOS-compatible clipboard fallback.
- Update the macOS bundle version to 1.0.1.

## 1.0.0

- Initial native macOS menu-bar application.
- Read selected text using macOS Accessibility permission.
- Generate QR codes locally with a global Shift-Command-Q shortcut.

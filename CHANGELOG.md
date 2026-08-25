# Changelog

## v1.0.3 selection hotfix

- Remember the last active non-CopyQR application so opening the QR panel cannot make CopyQR read its own (empty) selection.
- Re-check the foreground application at the instant the global shortcut fires, with the system-wide Accessibility lookup retained as a fallback.
- Read browser webpage selections from nested accessibility web areas and WebKit/Chromium text-marker ranges.
- Add a Chrome-only copy-and-restore fallback when Chrome does not expose webpage selection through Accessibility.
- Preserve every available pasteboard item and representation, and avoid restoring over a newer clipboard change.

## 1.0.3

- Replace version-specific ad-hoc signing with a stable private CopyQR release identity so Accessibility approval can persist across updates.
- Restore the proven v1.0.0 asynchronous Accessibility selection path and stop misreporting focused-element errors as missing permission.
- Strengthen visual copy confirmation on iPhone, where Safari does not expose custom web haptics.
- Add cross-platform, versioned maximum-level DEFLATE compression with automatic plain-text fallback.
- Preserve exact plain-text layout, including blank lines, indentation, tabs, and code formatting.
- Show QR payload bytes, percentage used, and original text bytes in the QR window.
- Give actionable size, reduction, and chunk guidance when text exceeds one QR.
- Show Accessibility readiness and provide one-click access to Accessibility Settings.
- Add optional Launch at Login.
- Add a polished copied animation and supported web haptic feedback on the phone receiver.
- Retain compatibility with v1.0.2 receiver links.

## 1.0.2

- Restore the global shortcut and Accessibility-based selection capture from v1.0.0.
- Use the short, Q-based **Control-Q** global shortcut.
- Remove the extra macOS Services enablement step.
- Read the active selection directly without changing the clipboard.
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

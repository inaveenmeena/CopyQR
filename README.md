# CopyQR v1.0.3

A tiny, native macOS menu-bar app that turns selected text into a QR code. Web links open directly; ordinary text opens a private, one-tap Copy page on your phone.

See [FUNCTIONALITY.md](FUNCTIONALITY.md) for the complete v1 feature set, permissions, and current limitations.

## Use

1. Open `dist/CopyQR.app`.
2. Press **Control-Q** once and allow CopyQR under **System Settings → Privacy & Security → Accessibility**.
3. Select text in any app and press **Control-Q**.
4. Scan the QR code with your phone. For ordinary text, tap **Copy text** on the receiver page.

Accessibility permission lets CopyQR read the text you actively select when its global shortcut is pressed. You can also copy text normally, click the QR icon in the macOS menu bar, and choose **Show Clipboard as QR**.

CopyQR reads the selection directly from the foreground app and never changes the clipboard, so clipboard managers such as Maccy do not record CopyQR activity.

The menu shows whether Accessibility and the global shortcut are ready, opens the correct Settings page when permission is missing, and offers an optional **Launch at Login** toggle.

CopyQR has no analytics and never uploads selected text. Ordinary text is encoded after `#` in the receiver URL; URL fragments are not sent in HTTP requests. The static receiver contains no accounts, storage, cookies, or third-party scripts.

The encoded receiver URL must still fit in one QR code. v1.0.3 applies maximum-level DEFLATE compression and automatically keeps the smaller of the compressed and plain payloads. Capacity therefore depends on the text: repetitive prose and code can fit substantially more than random or already-compressed content. The QR panel shows exact usage against the 2,900-byte payload limit and oversized selections receive a reduction estimate.

The receiver provides animated copy confirmation everywhere and vibration on browsers that implement the web Vibration API. iPhone Safari currently does not expose custom web haptics, so its confirmation is visual.

## Build

```sh
chmod +x build.sh
./build.sh
```

The build uses only Apple frameworks and the Clang compiler included with macOS Command Line Tools.

Release builds are signed with the private **CopyQR Local Release** certificate so macOS keeps one stable app identity across updates. Developers without that certificate can explicitly request an ad-hoc local build with `COPYQR_SIGNING_IDENTITY=- ./build.sh`; those local builds do not retain privacy permissions across rebuilds.

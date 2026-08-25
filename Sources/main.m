#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import <CoreImage/CoreImage.h>
#import <ServiceManagement/ServiceManagement.h>
#include <zlib.h>

static NSString *const CopyQRReceiverURL = @"https://inaveenmeena.github.io/CopyQR/";
static const NSUInteger CopyQRMaximumPayloadBytes = 2900;
static const OSType CopyQRHotKeySignature = 'CQR!';
static const UInt32 CopyQRHotKeyID = 1;

@interface QRPanelController : NSWindowController <NSWindowDelegate>
@property (nonatomic, copy) void (^onClose)(void);
- (instancetype)initWithImage:(NSImage *)image payloadBytes:(NSUInteger)payloadBytes sourceBytes:(NSUInteger)sourceBytes title:(NSString *)title;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) QRPanelController *panel;
@property (nonatomic, strong) NSMenuItem *permissionItem;
@property (nonatomic, strong) NSMenuItem *settingsItem;
@property (nonatomic, strong) NSMenuItem *launchItem;
@property (nonatomic) EventHotKeyRef hotKeyRef;
@property (nonatomic) EventHandlerRef eventHandler;
- (void)showClipboardAsQR;
- (void)captureSelectionAndShowQRFromPID:(pid_t)sourcePID;
@end

static NSString *CopyQRSelectedTextForElement(AXUIElementRef element) {
    if (!element) return nil;
    CFTypeRef selected = NULL;
    AXError error = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute, &selected);
    NSString *text = nil;
    if (error == kAXErrorSuccess && selected && CFGetTypeID(selected) == CFStringGetTypeID()) {
        text = [(__bridge NSString *)selected copy];
    }
    if (selected) CFRelease(selected);
    return text.length ? text : nil;
}

static NSString *CopyQRSelectedTextInAncestors(AXUIElementRef start) {
    if (!start) return nil;
    AXUIElementRef current = (AXUIElementRef)CFRetain(start);
    for (NSUInteger depth = 0; current && depth < 12; depth++) {
        NSString *text = CopyQRSelectedTextForElement(current);
        if (text.length) {
            CFRelease(current);
            return text;
        }
        CFTypeRef parent = NULL;
        AXUIElementCopyAttributeValue(current, kAXParentAttribute, &parent);
        CFRelease(current);
        current = parent && CFGetTypeID(parent) == AXUIElementGetTypeID() ? (AXUIElementRef)parent : NULL;
        if (parent && !current) CFRelease(parent);
    }
    if (current) CFRelease(current);
    return nil;
}

static OSStatus CopyQRHotKeyHandler(EventHandlerCallRef next, EventRef event, void *userData) {
    EventHotKeyID pressed = {0};
    OSStatus status = GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID,
                                        NULL, sizeof(pressed), NULL, &pressed);
    if (status == noErr && pressed.signature == CopyQRHotKeySignature && pressed.id == CopyQRHotKeyID) {
        AppDelegate *delegate = (__bridge AppDelegate *)userData;
        pid_t sourcePID = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
        dispatch_async(dispatch_get_main_queue(), ^{ [delegate captureSelectionAndShowQRFromPID:sourcePID]; });
    }
    return noErr;
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [self configureStatusItem];
    [self registerHotKey];
}

- (void)configureStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageWithSystemSymbolName:@"qrcode" accessibilityDescription:@"CopyQR"];
    self.statusItem.button.toolTip = @"Selected text to QR";

    NSMenu *menu = [[NSMenu alloc] init];
    menu.delegate = self;
    NSMenuItem *show = [[NSMenuItem alloc] initWithTitle:@"Show Clipboard as QR"
                                                  action:@selector(showClipboardAsQR)
                                           keyEquivalent:@""];
    show.target = self;
    [menu addItem:show];
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *shortcut = [[NSMenuItem alloc] initWithTitle:@"Shortcut: ⌃Q" action:nil keyEquivalent:@""];
    shortcut.enabled = NO;
    [menu addItem:shortcut];
    self.permissionItem = [[NSMenuItem alloc] initWithTitle:@"Accessibility: Checking…" action:nil keyEquivalent:@""];
    self.permissionItem.enabled = NO;
    [menu addItem:self.permissionItem];
    self.settingsItem = [[NSMenuItem alloc] initWithTitle:@"Open Accessibility Settings…"
                                                    action:@selector(openAccessibilitySettings)
                                             keyEquivalent:@""];
    self.settingsItem.target = self;
    [menu addItem:self.settingsItem];
    [menu addItem:[NSMenuItem separatorItem]];
    self.launchItem = [[NSMenuItem alloc] initWithTitle:@"Launch at Login"
                                                  action:@selector(toggleLaunchAtLogin:)
                                           keyEquivalent:@""];
    self.launchItem.target = self;
    [menu addItem:self.launchItem];
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit CopyQR" action:@selector(quitApp) keyEquivalent:@"q"];
    quit.target = self;
    [menu addItem:quit];
    self.statusItem.menu = menu;
}

- (void)menuWillOpen:(NSMenu *)menu {
    BOOL trusted = AXIsProcessTrusted();
    self.permissionItem.title = trusted ? @"Accessibility: Ready ✓" : @"Accessibility: Permission needed";
    self.settingsItem.hidden = trusted;

    SMAppServiceStatus status = SMAppService.mainAppService.status;
    self.launchItem.state = status == SMAppServiceStatusEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    self.launchItem.title = status == SMAppServiceStatusRequiresApproval
        ? @"Launch at Login (approval needed)"
        : @"Launch at Login";
}

- (void)registerHotKey {
    EventTypeSpec type = { kEventClassKeyboard, kEventHotKeyPressed };
    InstallEventHandler(GetApplicationEventTarget(), CopyQRHotKeyHandler, 1, &type,
                        (__bridge void *)self, &_eventHandler);
    EventHotKeyID identifier = { CopyQRHotKeySignature, CopyQRHotKeyID };
    OSStatus status = RegisterEventHotKey(kVK_ANSI_Q, controlKey, identifier,
                                          GetApplicationEventTarget(), 0, &_hotKeyRef);
    if (status != noErr) {
        [self showAlert:@"Shortcut unavailable"
                message:@"CopyQR couldn’t register ⌃Q because another app is already using it."];
    }
}

- (void)captureSelectionAndShowQRFromPID:(pid_t)sourcePID {
    NSDictionary *options = @{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES};
    if (!AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options)) {
        [self showAccessibilityHelp];
        return;
    }

    AXUIElementRef application = sourcePID > 0 ? AXUIElementCreateApplication(sourcePID) : NULL;
    CFTypeRef focused = NULL;
    if (application) AXUIElementCopyAttributeValue(application, kAXFocusedUIElementAttribute, &focused);

    NSString *text = focused && CFGetTypeID(focused) == AXUIElementGetTypeID()
        ? CopyQRSelectedTextInAncestors((AXUIElementRef)focused)
        : nil;

    if (text.length == 0 && application) {
        CFTypeRef window = NULL;
        AXUIElementCopyAttributeValue(application, kAXFocusedWindowAttribute, &window);
        if (window && CFGetTypeID(window) == AXUIElementGetTypeID()) {
            text = CopyQRSelectedTextForElement((AXUIElementRef)window);
        }
        if (window) CFRelease(window);
    }
    if (focused) CFRelease(focused);
    if (application) CFRelease(application);

    if (text.length == 0) {
        [self showAlert:@"No text selected"
                message:@"Select some text, then press ⌃Q. CopyQR reads only the selection exposed by the foreground app and never touches your clipboard."];
        return;
    }
    [self showTextAsQR:text];
}

- (NSData *)rawDeflateData:(NSData *)input strategy:(int)strategy {
    if (input.length > UINT_MAX) return nil;
    uLong bound = compressBound((uLong)input.length);
    NSMutableData *output = [NSMutableData dataWithLength:bound];
    z_stream stream = {0};
    if (deflateInit2(&stream, Z_BEST_COMPRESSION, Z_DEFLATED, -MAX_WBITS, 9, strategy) != Z_OK) return nil;
    stream.next_in = (Bytef *)input.bytes;
    stream.avail_in = (uInt)input.length;
    stream.next_out = output.mutableBytes;
    stream.avail_out = (uInt)output.length;
    int result = deflate(&stream, Z_FINISH);
    deflateEnd(&stream);
    if (result != Z_STREAM_END) return nil;
    output.length = stream.total_out;
    return output;
}

- (NSData *)smallestCompressedData:(NSData *)input {
    const int strategies[] = { Z_DEFAULT_STRATEGY, Z_FILTERED, Z_HUFFMAN_ONLY, Z_RLE };
    NSData *best = nil;
    for (NSUInteger i = 0; i < sizeof(strategies) / sizeof(strategies[0]); i++) {
        NSData *candidate = [self rawDeflateData:input strategy:strategies[i]];
        if (candidate && (!best || candidate.length < best.length)) best = candidate;
    }
    return best;
}

- (NSString *)base64URLStringForData:(NSData *)data {
    NSString *encoded = [data base64EncodedStringWithOptions:0];
    encoded = [[encoded stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
               stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [encoded stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
}

- (NSImage *)qrImageForData:(NSData *)data {
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"L" forKey:@"inputCorrectionLevel"];
    CIImage *output = filter.outputImage;
    if (!output) return nil;

    CGFloat scale = MAX(1, floor(560.0 / output.extent.size.width));
    CIImage *scaled = [output imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:scaled fromRect:scaled.extent];
    if (!cgImage) return nil;
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:scaled.extent.size];
    CGImageRelease(cgImage);
    return image;
}

- (void)showClipboardAsQR {
    NSString *text = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
    if (text.length == 0) {
        [self showAlert:@"Nothing to show" message:@"There is no text on the clipboard."];
        return;
    }

    [self showTextAsQR:text];
}

- (void)showTextAsQR:(NSString *)text {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSURLComponents *components = [NSURLComponents componentsWithString:trimmed];
    NSString *scheme = components.scheme.lowercaseString;
    BOOL isWebLink = ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) && components.host.length > 0;

    NSString *qrContent;
    NSUInteger sourceBytes = [text dataUsingEncoding:NSUTF8StringEncoding].length;
    if (isWebLink) {
        qrContent = trimmed;
    } else {
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSString *plainURL = [NSString stringWithFormat:@"%@#v1.%@", CopyQRReceiverURL,
                              [self base64URLStringForData:textData]];
        NSData *compressed = [self smallestCompressedData:textData];
        NSString *compressedURL = compressed
            ? [NSString stringWithFormat:@"%@#v2.%@", CopyQRReceiverURL,
               [self base64URLStringForData:compressed]]
            : nil;
        qrContent = compressedURL.length < plainURL.length ? compressedURL : plainURL;
    }

    NSData *payload = [qrContent dataUsingEncoding:NSUTF8StringEncoding];
    if (payload.length > CopyQRMaximumPayloadBytes) {
        NSUInteger over = payload.length - CopyQRMaximumPayloadBytes;
        NSUInteger percent = (NSUInteger)ceil((double)over * 100.0 / (double)payload.length);
        NSUInteger parts = (NSUInteger)ceil((double)payload.length / (double)CopyQRMaximumPayloadBytes);
        [self showAlert:@"Text is too large"
                message:[NSString stringWithFormat:@"This selection is %lu text bytes and needs %lu QR bytes after the best available compression. That is %lu bytes over the 2,900-byte limit. Shorten it by about %lu%% or split it into roughly %lu chunks.",
                         (unsigned long)sourceBytes, (unsigned long)payload.length,
                         (unsigned long)over, (unsigned long)percent, (unsigned long)parts]];
        return;
    }

    NSImage *image = [self qrImageForData:payload];
    if (!image) {
        [self showAlert:@"Couldn’t create QR" message:@"Try copying a shorter piece of text."];
        return;
    }

    [self.panel close];
    QRPanelController *controller = [[QRPanelController alloc] initWithImage:image
                                                                payloadBytes:payload.length
                                                                 sourceBytes:sourceBytes
                                                                       title:isWebLink ? @"Scan to open" : @"Scan to copy"];
    self.panel = controller;
    __weak typeof(self) weakSelf = self;
    __weak QRPanelController *weakController = controller;
    controller.onClose = ^{
        if (weakSelf.panel == weakController) weakSelf.panel = nil;
    };
    [controller showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [controller.window makeKeyAndOrderFront:nil];
}

- (void)showAccessibilityHelp {
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Allow Accessibility access";
    alert.informativeText = @"Enable CopyQR in System Settings → Privacy & Security → Accessibility, then press ⌃Q again.";
    [alert addButtonWithTitle:@"Open Settings"];
    [alert addButtonWithTitle:@"Not Now"];
    if ([alert runModal] == NSAlertFirstButtonReturn) [self openAccessibilitySettings];
}

- (void)openAccessibilitySettings {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
    [NSWorkspace.sharedWorkspace openURL:url];
}

- (void)toggleLaunchAtLogin:(NSMenuItem *)sender {
    SMAppService *service = SMAppService.mainAppService;
    NSError *error = nil;
    BOOL turningOff = service.status == SMAppServiceStatusEnabled || service.status == SMAppServiceStatusRequiresApproval;
    BOOL succeeded = turningOff ? [service unregisterAndReturnError:&error] : [service registerAndReturnError:&error];
    if (!succeeded) {
        [self showAlert:@"Couldn’t update Launch at Login" message:error.localizedDescription ?: @"Try again from System Settings → General → Login Items."];
    }
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)quitApp { [NSApp terminate:nil]; }

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (self.hotKeyRef) UnregisterEventHotKey(self.hotKeyRef);
    if (self.eventHandler) RemoveEventHandler(self.eventHandler);
}

@end

@implementation QRPanelController

- (instancetype)initWithImage:(NSImage *)image payloadBytes:(NSUInteger)payloadBytes sourceBytes:(NSUInteger)sourceBytes title:(NSString *)titleText {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 620, 680)
                                                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskFullSizeContentView
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
    self = [super initWithWindow:window];
    if (self) {
        window.title = @"CopyQR";
        window.titlebarAppearsTransparent = YES;
        window.movableByWindowBackground = YES;
        window.backgroundColor = NSColor.windowBackgroundColor;
        window.level = NSFloatingWindowLevel;
        window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
        window.delegate = self;
        [window center];
        [self buildContentWithImage:image payloadBytes:payloadBytes sourceBytes:sourceBytes title:titleText];
    }
    return self;
}

- (void)buildContentWithImage:(NSImage *)image payloadBytes:(NSUInteger)payloadBytes sourceBytes:(NSUInteger)sourceBytes title:(NSString *)titleText {
    NSView *content = self.window.contentView;
    NSImageView *imageView = [[NSImageView alloc] init];
    imageView.image = image;
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    imageView.wantsLayer = YES;
    imageView.layer.magnificationFilter = kCAFilterNearest;

    NSTextField *title = [NSTextField labelWithString:titleText];
    title.font = [NSFont systemFontOfSize:22 weight:NSFontWeightSemibold];
    title.alignment = NSTextAlignmentCenter;

    NSUInteger percent = (NSUInteger)ceil((double)payloadBytes * 100.0 / (double)CopyQRMaximumPayloadBytes);
    NSTextField *detail = [NSTextField labelWithString:[NSString stringWithFormat:@"%lu / 2,900 QR bytes • %lu%% used • %lu text bytes",
                                                        (unsigned long)payloadBytes, (unsigned long)percent, (unsigned long)sourceBytes]];
    detail.font = [NSFont systemFontOfSize:13];
    detail.textColor = NSColor.secondaryLabelColor;
    detail.alignment = NSTextAlignmentCenter;

    NSStackView *stack = [NSStackView stackViewWithViews:@[title, imageView, detail]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeCenterX;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [stack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [stack.topAnchor constraintEqualToAnchor:content.topAnchor constant:54],
        [stack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-26],
        [imageView.widthAnchor constraintEqualToConstant:550],
        [imageView.heightAnchor constraintEqualToConstant:550]
    ]];
}

- (void)cancelOperation:(id)sender { [self close]; }
- (void)windowWillClose:(NSNotification *)notification { if (self.onClose) self.onClose(); }
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}

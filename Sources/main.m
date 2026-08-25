#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import <CoreImage/CoreImage.h>

static NSString *const CopyQRReceiverURL = @"https://inaveenmeena.github.io/CopyQR/";
static const OSType CopyQRHotKeySignature = 'CQR!';
static const UInt32 CopyQRHotKeyID = 1;

@interface QRPanelController : NSWindowController <NSWindowDelegate>
@property (nonatomic, copy) void (^onClose)(void);
- (instancetype)initWithImage:(NSImage *)image byteCount:(NSUInteger)byteCount title:(NSString *)title;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) QRPanelController *panel;
@property (nonatomic) EventHotKeyRef hotKeyRef;
@property (nonatomic) EventHandlerRef eventHandler;
- (void)showClipboardAsQR;
- (void)captureSelectionAndShowQR;
@end

static OSStatus CopyQRHotKeyHandler(EventHandlerCallRef next, EventRef event, void *userData) {
    EventHotKeyID pressed = {0};
    OSStatus status = GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID,
                                        NULL, sizeof(pressed), NULL, &pressed);
    if (status == noErr && pressed.signature == CopyQRHotKeySignature && pressed.id == CopyQRHotKeyID) {
        AppDelegate *delegate = (__bridge AppDelegate *)userData;
        dispatch_async(dispatch_get_main_queue(), ^{ [delegate captureSelectionAndShowQR]; });
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
    NSMenuItem *show = [[NSMenuItem alloc] initWithTitle:@"Show Clipboard as QR"
                                                  action:@selector(showClipboardAsQR)
                                           keyEquivalent:@""];
    show.target = self;
    [menu addItem:show];
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *shortcut = [[NSMenuItem alloc] initWithTitle:@"Shortcut: ⌃Q" action:nil keyEquivalent:@""];
    shortcut.enabled = NO;
    [menu addItem:shortcut];
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit CopyQR" action:@selector(quitApp) keyEquivalent:@"q"];
    quit.target = self;
    [menu addItem:quit];
    self.statusItem.menu = menu;
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

- (void)captureSelectionAndShowQR {
    NSDictionary *options = @{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES};
    if (!AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options)) {
        [self showAlert:@"Allow Accessibility access"
                message:@"Enable CopyQR in System Settings → Privacy & Security → Accessibility, then press ⌃Q again."];
        return;
    }

    AXUIElementRef system = AXUIElementCreateSystemWide();
    CFTypeRef focused = NULL;
    AXError focusedError = AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute, &focused);
    CFRelease(system);

    CFTypeRef selected = NULL;
    AXError selectedError = focusedError == kAXErrorSuccess && focused
        ? AXUIElementCopyAttributeValue((AXUIElementRef)focused, kAXSelectedTextAttribute, &selected)
        : kAXErrorFailure;
    if (focused) CFRelease(focused);

    NSString *text = nil;
    if (selectedError == kAXErrorSuccess && selected && CFGetTypeID(selected) == CFStringGetTypeID()) {
        text = [(__bridge NSString *)selected copy];
    }
    if (selected) CFRelease(selected);

    if (text.length == 0) {
        [self showAlert:@"No text selected"
                message:@"Select some text, then press ⌃Q. If an app doesn’t expose its selection to macOS, use CopyQR’s clipboard menu option."];
        return;
    }
    [self showTextAsQR:text];
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
    if (isWebLink) {
        qrContent = trimmed;
    } else {
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSString *encoded = [textData base64EncodedStringWithOptions:0];
        encoded = [[encoded stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
                   stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        encoded = [encoded stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
        qrContent = [NSString stringWithFormat:@"%@#v1.%@", CopyQRReceiverURL, encoded];
    }

    NSData *payload = [qrContent dataUsingEncoding:NSUTF8StringEncoding];
    if (payload.length > 2900) {
        [self showAlert:@"Text is too large"
                message:[NSString stringWithFormat:@"This text needs %lu QR bytes after URL encoding. CopyQR v1.0.2 supports up to 2,900, which is at most 2,143 UTF-8 text bytes. Try a shorter selection.", (unsigned long)payload.length]];
        return;
    }

    NSImage *image = [self qrImageForData:payload];
    if (!image) {
        [self showAlert:@"Couldn’t create QR" message:@"Try copying a shorter piece of text."];
        return;
    }

    [self.panel close];
    QRPanelController *controller = [[QRPanelController alloc] initWithImage:image
                                                                   byteCount:[text dataUsingEncoding:NSUTF8StringEncoding].length
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

- (instancetype)initWithImage:(NSImage *)image byteCount:(NSUInteger)byteCount title:(NSString *)titleText {
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
        [self buildContentWithImage:image byteCount:byteCount title:titleText];
    }
    return self;
}

- (void)buildContentWithImage:(NSImage *)image byteCount:(NSUInteger)byteCount title:(NSString *)titleText {
    NSView *content = self.window.contentView;
    NSImageView *imageView = [[NSImageView alloc] init];
    imageView.image = image;
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    imageView.wantsLayer = YES;
    imageView.layer.magnificationFilter = kCAFilterNearest;

    NSTextField *title = [NSTextField labelWithString:titleText];
    title.font = [NSFont systemFontOfSize:22 weight:NSFontWeightSemibold];
    title.alignment = NSTextAlignmentCenter;

    NSTextField *detail = [NSTextField labelWithString:[NSString stringWithFormat:@"%lu text bytes • Press Esc to close", (unsigned long)byteCount]];
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

#import "KneeboardViewController.h"
#import "AppDelegate.h"
#import "PreferencesViewController.h"

@interface KneeboardViewController ()
// Add a property to hold the settings menu
@property (strong, nonatomic) NSMenu *settingsMenu;
@end

@implementation KneeboardViewController

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 390, 388)];
    // Make the main view layer-backed
    view.wantsLayer = YES;
    // *** REVERT to clearColor ***
    // Make the container view clear again:
    view.layer.backgroundColor = [NSColor clearColor].CGColor;
    // Ensure text view draws its background which respects dark/light mode:
    // view.layer.backgroundColor = [NSColor textBackgroundColor].CGColor; // <- REMOVE THIS LINE or comment out

    // --- Create Text View to fill the entire view ---
    self.textView = [[NSTextView alloc] initWithFrame:view.bounds]; // Use view's bounds
    self.textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.textView.font = [NSFont systemFontOfSize:13.0];
    // ENSURE TextView draws its background
    self.textView.drawsBackground = YES;
    self.textView.backgroundColor = [NSColor textBackgroundColor]; // This respects appearance
    self.textView.textColor = [NSColor textColor]; // This respects appearance

    // --- Add Padding to the Text View ---
    // Add padding/inset at the top so text content doesn't touch the edge/button
    // Note: If padding causes the gray bar, consider adjusting padding or making the text view frame slightly smaller than the container.
    self.textView.textContainerInset = NSMakeSize(0, 10); // Width inset 0, Height inset 10 (top/bottom)

    // --- Create the Settings Menu ---
    self.settingsMenu = [[NSMenu alloc] init];
    // Add About item (will need a target/action)
    [self.settingsMenu addItemWithTitle:@"About Kneeboard" action:@selector(showAbout:) keyEquivalent:@""];
    [self.settingsMenu addItem:[NSMenuItem separatorItem]];
    // Add Save item (targets self for saveAction:)
    [self.settingsMenu addItemWithTitle:@"Save..." action:@selector(saveAction:) keyEquivalent:@"s"]; // Use 's' for Cmd+S too
    [self.settingsMenu addItem:[NSMenuItem separatorItem]];
    // Add standard Edit items (targets will be set dynamically or use nil for first responder)
    [self.settingsMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [self.settingsMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [self.settingsMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [self.settingsMenu addItem:[NSMenuItem separatorItem]];
    [self.settingsMenu addItemWithTitle:@"Preferences..." action:@selector(showPreferences:) keyEquivalent:@""];
    [self.settingsMenu addItem:[NSMenuItem separatorItem]];
    [self.settingsMenu addItemWithTitle:@"Quit Kneeboard" action:@selector(terminate:) keyEquivalent:@"q"];

    // --- Add Settings Cogwheel Button ---
    // Adjust position to be relative to the top-right corner of the main view
    CGFloat buttonSize = 25.0;
    CGFloat margin = 8.0;
    NSButton *settingsButton = [[NSButton alloc] initWithFrame:NSMakeRect(view.bounds.size.width - buttonSize - margin,
                                                                          view.bounds.size.height - buttonSize - margin,
                                                                          buttonSize, buttonSize)];
    NSImage *cogIcon = [NSImage imageWithSystemSymbolName:@"gearshape" accessibilityDescription:@"Settings"];
    if (!cogIcon) { cogIcon = [NSImage imageNamed:NSImageNameActionTemplate]; }
    [settingsButton setImage:cogIcon];
    [settingsButton setButtonType:NSButtonTypeMomentaryPushIn];
    [settingsButton setBordered:NO];
    // Make button non-transparent again as requested by user
    [settingsButton setTransparent:NO];
    settingsButton.focusRingType = NSFocusRingTypeNone;

    // Set autoresizing mask to keep it in the top-right
    settingsButton.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;

    [settingsButton setTarget:self];
    [settingsButton setAction:@selector(settingsButtonClicked:)];

    // Add text view first, then button on top
    [view addSubview:self.textView];
    [view addSubview:settingsButton positioned:NSWindowAbove relativeTo:self.textView];

    self.view = view;

    // Remove old label code if it exists (should be gone already)
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Any additional setup after the view loads
}

- (void)focusTextView {
    // Make the text view the first responder to receive key events
    BOOL success = [self.view.window makeFirstResponder:self.textView];
    // Log the result
    NSLog(@"[KneeboardViewController focusTextView] makeFirstResponder success: %d", success);
    if (!success) {
        NSLog(@"[KneeboardViewController focusTextView] Window: %@", self.view.window);
        NSLog(@"[KneeboardViewController focusTextView] TextView: %@", self.textView);
        NSLog(@"[KneeboardViewController focusTextView] TextView editable: %d", self.textView.isEditable);
        NSLog(@"[KneeboardViewController focusTextView] TextView selectable: %d", self.textView.isSelectable);
    }
    // Optional: Select all text or move cursor to end
    // [self.textView setSelectedRange:NSMakeRange(self.textView.string.length, 0)];
}

- (void)saveAction:(id)sender {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = @[@"txt"];
    savePanel.nameFieldStringValue = @"kneeboard_note.txt"; // *** Updated suggested filename ***

    // Use weakSelf to avoid potential retain cycle inside the block
    // *** Updated weakSelf type ***
    __weak KneeboardViewController *weakSelf = self;
    [savePanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *url = savePanel.URL;
            if (url && weakSelf) {
                NSString *content = weakSelf.textView.string;
                NSError *error = nil;
                BOOL success = [content writeToURL:url
                                        atomically:YES
                                        encoding:NSUTF8StringEncoding
                                            error:&error];
                if (!success) {
                    // Handle error (e.g., show an alert)
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"Error Saving File";
                    alert.informativeText = [error localizedDescription];
                    alert.alertStyle = NSAlertStyleWarning;
                    [alert runModal];
                } else {
                    // Optionally close popover after successful save
                    // [weakSelf.appDelegate closePopover:nil];
                }
            }
        }
    }];
}

// Action method for the settings button
- (void)settingsButtonClicked:(NSButton *)sender {
    // Set targets for menu items before showing
    // About targets self
    [[self.settingsMenu itemWithTitle:@"About Kneeboard"] setTarget:self];
    // Save targets self
    [[self.settingsMenu itemWithTitle:@"Save..."] setTarget:self];
    // Cut, Copy, Paste target nil (first responder, which should be the text view)
    [[self.settingsMenu itemWithTitle:@"Cut"] setTarget:nil];
    [[self.settingsMenu itemWithTitle:@"Copy"] setTarget:nil];
    [[self.settingsMenu itemWithTitle:@"Paste"] setTarget:nil];
    // Preferences targets self
    [[self.settingsMenu itemWithTitle:@"Preferences..."] setTarget:self];
    // Quit targets the application
    [[self.settingsMenu itemWithTitle:@"Quit Kneeboard"] setTarget:NSApp];

    // Show the menu attached to the button
    [self.settingsMenu popUpMenuPositioningItem:nil
                                   atLocation:NSMakePoint(0, sender.bounds.size.height + 5)
                                       inView:sender];
}

// Placeholder action for About
- (void)showAbout:(id)sender {
    NSLog(@"[KneeboardViewController] About clicked!");
    // Use standard About panel
    [NSApp orderFrontStandardAboutPanel:sender];
}

// Action method for the Preferences menu item
- (void)showPreferences:(id)sender {
    NSLog(@"[KneeboardViewController] Preferences clicked!");

    // Check if a preferences window controller already exists/is open? (Optional, for single window)
    // For simplicity, we create a new one each time here.

    PreferencesViewController *prefsVC = [[PreferencesViewController alloc] init];
    NSWindow *prefsWindow = [NSWindow windowWithContentViewController:prefsVC];
    [prefsWindow setTitle:@"Kneeboard Preferences"];
    // Make it a utility-style window if desired
    // prefsWindow.styleMask |= NSWindowStyleMaskUtilityWindow;
    prefsWindow.level = NSFloatingWindowLevel; // Keep it above normal windows

    // Create a window controller to manage it
    NSWindowController *prefsWindowController = [[NSWindowController alloc] initWithWindow:prefsWindow];

    // Show the window
    [prefsWindowController showWindow:self];

    // Optional: Keep a reference to the window controller if you need to prevent multiple windows
    // self.preferencesWindowController = prefsWindowController;

     // Make the window front and key
    [prefsWindow makeKeyAndOrderFront:sender];
}

@end 
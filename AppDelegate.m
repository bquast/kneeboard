// AppDelegate.m
#import "AppDelegate.h"
#import "KneeboardViewController.h" // Import the actual view controller header
#import "PreferencesViewController.h" // Assuming notification name is defined here or globally

// Add these constants near the top, after imports
NSString * const kPrefWidthKey = @"popoverWidth";
NSString * const kPrefHeightKey = @"popoverHeight";
NSString * const kPrefAppearanceKey = @"appearanceSetting"; // 0: System, 1: Light, 2: Dark

@interface AppDelegate ()
// Status item shown in the menu bar
@property (strong) NSStatusItem *statusItem;
// The popover window that appears
@property (strong) NSPopover *popover;
// The view controller managing the popover's content (text view, button)
@property (strong) KneeboardViewController *kneeboardViewController;
// Used to monitor events like Cmd+Enter or clicks outside the popover to close it
@property (strong, nonatomic) id popoverEventMonitor;
// Add the new method declaration
- (void)handleStatusItemClick:(id)sender;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // --- Register Default Preferences ---
    NSDictionary *defaultPrefs = @{
        kPrefWidthKey: @(390), // Current width
        kPrefHeightKey: @(388), // Current height
        kPrefAppearanceKey: @(0) // Default to System appearance
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
    // --- End Register Defaults ---

    // Apply initial appearance setting
    [self applyAppearanceSetting];

    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    // Initialize the view controller first
    self.kneeboardViewController = [[KneeboardViewController alloc] init];
    self.kneeboardViewController.appDelegate = self;
    
    // Create status item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"📝";
    
    // Set up button for click
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(showPopover:);
    
    // Create main menu (invisible but handles Cmd+Q and Edit shortcuts)
    NSMenu *mainMenu = [[NSMenu alloc] init];
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenuItem setSubmenu:appMenu];
    [mainMenu addItem:appMenuItem];
    
    // Add Quit menu item with Cmd+Q shortcut
    [appMenu addItemWithTitle:@"Quit" 
                     action:@selector(terminate:) 
              keyEquivalent:@"q"];
              
    // Add Edit menu for standard commands
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];
    [mainMenu addItem:editMenuItem];
    
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];

    [NSApp setMainMenu:mainMenu];

    // --- Add Observer for Preference Changes ---
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePrefsChange:)
                                                 name:kPrefsChangedNotification
                                               object:nil];
    // --- End Add Observer ---
}

- (void)showPopover:(id)sender {
    // Check if the popover exists and is already shown
    if (self.popover && self.popover.isShown) {
        [self closePopover:sender];
        return; // Exit the method after closing
    }

    // Only handle left clicks for showing (right-click/two-finger click are handled by the menu)
    NSEvent *event = [NSApp currentEvent];
    if (event && event.type != NSEventTypeLeftMouseUp) {
         return;
     }

    // --- Read size from UserDefaults ---
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat width = [defaults floatForKey:kPrefWidthKey];
    CGFloat height = [defaults floatForKey:kPrefHeightKey];
    // --- End Read size ---

    // If popover doesn't exist or isn't shown, create and show it
    if (!self.popover) {
        self.popover = [[NSPopover alloc] init];
        self.popover.contentViewController = self.kneeboardViewController;
        self.popover.behavior = NSPopoverBehaviorTransient;
    }
    // --- Set size from UserDefaults ---
    self.popover.contentSize = NSMakeSize(width, height);
    // *** Explicitly set popover appearance ***
    self.popover.appearance = NSApp.appearance; // Match the current app appearance
    // --- End Set size ---

    // Show the popover
    NSStatusBarButton *button = self.statusItem.button;
    [self.popover showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMinY];

    // Focus the text view *after* showing
    // Use dispatch_async to ensure it happens after the popover is fully displayed
    dispatch_async(dispatch_get_main_queue(), ^{
        [self focusTextViewAndMakeKeyWindow];
    });
    
    // Start monitoring events ONLY when popover is shown
    if (!self.popoverEventMonitor) {
        __weak AppDelegate *weakSelf = self;
        self.popoverEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskKeyDown) handler:^(NSEvent * _Nonnull event) {
            // Check for Cmd+Enter (keyCode 36)
            if (event.keyCode == 36 && (event.modifierFlags & NSEventModifierFlagCommand)) {
                NSLog(@"[AppDelegate eventMonitor] Cmd+Enter detected! Closing popover.");
                [weakSelf closePopover:nil];
                return (NSEvent *)nil; // Consume the event
            }
            // Check for Cmd+S (keyCode 1)
            if (event.keyCode == 1 && (event.modifierFlags & NSEventModifierFlagCommand)) {
                NSLog(@"[AppDelegate eventMonitor] Cmd+S detected! Calling save.");
                [weakSelf.kneeboardViewController saveAction:nil];
                return (NSEvent *)nil; // Consume the event
            }
            
            // Pass other key events through for text view handling
            return event;
        }];
    }
}

// *** RESTORE this helper method ***
- (void)focusTextViewAndMakeKeyWindow {
    // First, make the text view the first responder
    [self.kneeboardViewController focusTextView];

    // Then, explicitly make the popover's window the key window
    NSWindow *popoverWindow = self.kneeboardViewController.view.window;
    if (popoverWindow) {
        NSLog(@"[AppDelegate focusTextViewAndMakeKeyWindow] Making window key: %@", popoverWindow);
        [popoverWindow makeKeyAndOrderFront:nil];
    } else {
         NSLog(@"[AppDelegate focusTextViewAndMakeKeyWindow] Warning: Popover window not found when trying to make key.");
    }
}

// Closes the popover and stops event monitoring
- (void)closePopover:(id)sender {
    [self.popover performClose:sender];

    // Stop monitoring events when the popover is closed
    if (self.popoverEventMonitor) {
        NSLog(@"[AppDelegate closePopover] Removing event monitor.");
        [NSEvent removeMonitor:self.popoverEventMonitor];
        self.popoverEventMonitor = nil;
    }
}

// Optional: Decide if the app should terminate when the (non-existent) last window closes.
// For a menu bar app, we usually want it to keep running.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return NO; // Keep running even without visible windows
}

// Optional: Close popover if app becomes inactive
- (void)applicationWillResignActive:(NSNotification *)notification {
    // Uncomment if you want the popover to close when the app loses focus
    // if (self.popover.isShown) {
    //    [self closePopover:nil];
    // }
}

// Clean up when the application is about to terminate
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Remove status item from the status bar if it exists
    if (self.statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    }
    // Any other cleanup if needed

    [[NSNotificationCenter defaultCenter] removeObserver:self]; // Remove observer
}

// Add this method to address the secure coding warning
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

// --- Add method to apply appearance ---
- (void)applyAppearanceSetting {
    NSInteger appearanceSetting = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefAppearanceKey];
    NSAppearance *appearance = nil;
    switch (appearanceSetting) {
        case 1: // Light
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            break;
        case 2: // Dark
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
            break;
        default: // System (0) or unknown
            appearance = nil; // Setting to nil uses system
            break;
    }
    // Apply to the whole app, or just the popover if desired
    NSApp.appearance = appearance;
    // If you only want the popover affected:
    // self.popover.appearance = appearance; // Needs to be done when popover is created/shown
}

// Method called when preferences change notification is received
- (void)handlePrefsChange:(NSNotification *)notification {
    NSLog(@"[AppDelegate] Preferences changed notification received.");

    // Re-apply appearance setting TO THE WHOLE APP
    [self applyAppearanceSetting];

    // Update popover size if it's currently visible
    if (self.popover && self.popover.isShown) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        CGFloat width = [defaults floatForKey:kPrefWidthKey];
        CGFloat height = [defaults floatForKey:kPrefHeightKey];
        self.popover.contentSize = NSMakeSize(width, height);
        NSLog(@"[AppDelegate] Updated popover size to: %.0f x %.0f", width, height);
    }
}

@end


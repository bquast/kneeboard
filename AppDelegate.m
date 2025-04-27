// AppDelegate.m
#import "AppDelegate.h"
#import "KneeboardViewController.h" // Import the actual view controller header

@interface AppDelegate ()
// Status item shown in the menu bar
@property (strong, nonatomic) NSStatusItem *statusItem;
// The popover window that appears
@property (strong, nonatomic) NSPopover *popover;
// The view controller managing the popover's content (text view, button)
@property (strong, nonatomic) KneeboardViewController *kneeboardViewController;
// Used to monitor events like Cmd+Enter or clicks outside the popover to close it
@property (strong, nonatomic) id popoverEventMonitor;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 1. Create the View Controller for the popover content
    self.kneeboardViewController = [[KneeboardViewController alloc] init];
    // Pass a reference to the AppDelegate so the ViewController can call closePopover:
    self.kneeboardViewController.appDelegate = self;

    // 2. Create the Popover
    self.popover = [[NSPopover alloc] init];
    self.popover.contentViewController = self.kneeboardViewController;
    // Set popover behavior: transient means it closes when clicking outside
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.animates = YES; // Optional: adds fade-in/out animation

    // 3. Create the Status Bar Item
    // Get a status item from the system status bar with variable length (adjusts to content)
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    // 4. Configure the Status Bar Button
    if (self.statusItem.button) {
        // Use a simple text character as the icon (or an image)
        self.statusItem.button.title = @"📝";
        // Set the action to call when the button is clicked
        self.statusItem.button.action = @selector(togglePopover:);
        // Set the target (object that implements the action) to self (AppDelegate)
        self.statusItem.button.target = self;
    }

    // Create main menu (invisible but functional)
    NSMenu *mainMenu = [[NSMenu alloc] init];
    [NSApp setMainMenu:mainMenu];
    
    // Application menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenuItem setSubmenu:appMenu];
    [mainMenu addItem:appMenuItem];
    
    // Edit menu
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];
    [mainMenu addItem:editMenuItem];
    
    // Add standard Edit menu items
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];

    // --- Optional: Register Default Settings ---
    // If you had settings like the old app, register them here. None needed for this version yet.
    // NSDictionary *defaults = @{@"someSettingKey": @YES};
    // [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

// Action method called when the status bar item is clicked
- (void)togglePopover:(id)sender {
    if (self.popover.isShown) {
        [self closePopover:sender];
    } else {
        [self showPopover:sender];
    }
}

// Shows the popover attached to the status item button
- (void)showPopover:(id)sender {
    if (self.statusItem.button) {
        // Display the popover positioned relative to the status item button
        [self.popover showRelativeToRect:self.statusItem.button.bounds
                                  ofView:self.statusItem.button
                           preferredEdge:NSRectEdgeMinY]; // Show below the button

        NSLog(@"[AppDelegate showPopover] Attempting to focus text view and make window key...");
        // *** RESTORE: Call helper method after delay ***
        [self performSelector:@selector(focusTextViewAndMakeKeyWindow) withObject:nil afterDelay:0];

        // Event monitor for keyboard and mouse events
        __weak AppDelegate *weakSelf = self;
        self.popoverEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskKeyDown | NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown) handler:^(NSEvent * _Nonnull event) {
            if (event.type == NSEventTypeKeyDown) {
                // Check for Cmd+Enter (keyCode 36)
                if (event.keyCode == 36 && (event.modifierFlags & NSEventModifierFlagCommand)) {
                    NSLog(@"[AppDelegate eventMonitor] Cmd+Enter detected! Closing popover.");
                    [weakSelf closePopover:sender];
                    return (NSEvent *)nil;
                }
                // Check for Cmd+S (keyCode 1)
                if (event.keyCode == 1 && (event.modifierFlags & NSEventModifierFlagCommand)) {
                    NSLog(@"[AppDelegate eventMonitor] Cmd+S detected! Calling save.");
                    [weakSelf.kneeboardViewController saveAction:nil];
                    return (NSEvent *)nil;
                }
            }

            // Pass all other events
            NSLog(@"[AppDelegate eventMonitor] Passing event: %@", event);
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
}

// Add this method to address the secure coding warning
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end


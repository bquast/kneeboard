// AppDelegate.m
#import "AppDelegate.h"
#import "KneeboardViewController.h" // Import the actual view controller header

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
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    // Initialize the view controller first
    self.kneeboardViewController = [[KneeboardViewController alloc] init];
    self.kneeboardViewController.appDelegate = self;
    
    // Create status item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"✍️";
    
    // Set up button for click
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(showPopover:);
}

- (void)showPopover:(id)sender {
    // Only handle left clicks here
    NSEvent *event = [NSApp currentEvent];
    if (event.type != NSEventTypeLeftMouseUp) {
        return;
    }
    
    // Show popover
    if (!self.popover) {
        self.popover = [[NSPopover alloc] init];
        self.popover.contentViewController = self.kneeboardViewController;
        self.popover.behavior = NSPopoverBehaviorTransient;
        self.popover.contentSize = NSMakeSize(390, 388);
    }
    
    [self.popover showRelativeToRect:self.statusItem.button.bounds 
                            ofView:self.statusItem.button 
                     preferredEdge:NSMinYEdge];
    
    [self focusTextViewAndMakeKeyWindow];
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


#import "KneeboardViewController.h"
#import "AppDelegate.h"

@interface KneeboardViewController ()

@end

@implementation KneeboardViewController

- (void)loadView {
    // Create the main container view
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 230)]; // Increased height for button

    // Create a ScrollView to hold the TextView
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(5, 35, 190, 190)]; // Adjusted frame
    scrollView.hasVerticalScroller = YES;
    scrollView.borderType = NSBezelBorder; // Optional: adds a border

    // Create the TextView
    self.textView = [[NSTextView alloc] initWithFrame:scrollView.bounds];
    self.textView.minSize = NSMakeSize(0.0, scrollView.contentSize.height); // Basic setup for resizing
    self.textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
    self.textView.verticallyResizable = YES;
    self.textView.horizontallyResizable = NO; // Keep horizontal size fixed
    self.textView.autoresizingMask = NSViewWidthSizable;
    [self.textView.textContainer setContainerSize:NSMakeSize(scrollView.contentSize.width, FLT_MAX)];
    [self.textView.textContainer setWidthTracksTextView:YES];

    // Configure TextView properties
    self.textView.allowsUndo = YES;
    self.textView.font = [NSFont userFixedPitchFontOfSize:12.0]; // Use a monospaced font
    self.textView.richText = NO; // Keep it plain text
    self.textView.importsGraphics = NO;
    self.textView.automaticQuoteSubstitutionEnabled = NO;
    self.textView.automaticDashSubstitutionEnabled = NO;
    self.textView.automaticTextReplacementEnabled = NO;
    self.textView.smartInsertDeleteEnabled = NO;

    // *** Explicitly set editable and selectable ***
    self.textView.editable = YES;
    self.textView.selectable = YES;

    // *** Add delegate assignment back ***
    self.textView.delegate = self;

    // Add TextView to ScrollView
    scrollView.documentView = self.textView;

    // Create the Save Button
    NSButton *saveButton = [NSButton buttonWithTitle:@"Save" target:self action:@selector(saveAction:)];
    saveButton.bezelStyle = NSBezelStyleRounded;
    saveButton.frame = NSMakeRect(10, 5, 80, 25); // Positioned at the bottom-left

    // Add subviews to the main view
    [view addSubview:scrollView];
    [view addSubview:saveButton];

    // Set the main view for this controller
    self.view = view;
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

// *** ADD BACK textView:doCommandBySelector: ***
- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    NSLog(@"[KneeboardViewController textView:doCommandBySelector:] selector: %@", NSStringFromSelector(commandSelector));
    NSLog(@"[KneeboardViewController textView:doCommandBySelector:] Current First Responder: %@", [self.view.window firstResponder]);

    // Let NSTextView handle all commands by default
    NSLog(@"[KneeboardViewController textView:doCommandBySelector:] Passing command to NSTextView.");
    return NO;
}

@end 
#import "KneeboardViewController.h"
#import "AppDelegate.h"

@interface KneeboardViewController ()

@end

@implementation KneeboardViewController

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 390, 388)];  // 190+200, 188+200
    
    self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 390, 388)];  // 190+200, 188+200
    self.textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.textView.font = [NSFont systemFontOfSize:13.0];
    self.textView.drawsBackground = YES;
    self.textView.backgroundColor = [NSColor whiteColor];
    
    [view addSubview:self.textView];
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
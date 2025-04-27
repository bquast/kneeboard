// AppDelegate.h
#import <Cocoa/Cocoa.h>

// Forward declare KneeboardViewController to avoid circular imports
@class KneeboardViewController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

// Add a method signature for closing the popover, if KneepadViewController needs it
- (void)closePopover:(id)sender;

@end


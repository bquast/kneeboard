#import <Cocoa/Cocoa.h>

// Forward declare AppDelegate to avoid circular imports
@class AppDelegate;

// *** Changed class name here ***
@interface KneeboardViewController : NSViewController

@property (strong, nonatomic) NSTextView *textView;
@property (weak, nonatomic) AppDelegate *appDelegate; // Weak reference to avoid retain cycle

- (void)focusTextView;

@end 
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// Notification name for when preferences change that require UI updates
extern NSString * const kPrefsChangedNotification;

@interface PreferencesViewController : NSViewController

@end

NS_ASSUME_NONNULL_END 
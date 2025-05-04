#import "PreferencesViewController.h"

// Import keys defined elsewhere (e.g., AppDelegate.m for now)
extern NSString * const kPrefWidthKey;
extern NSString * const kPrefHeightKey;
extern NSString * const kPrefAppearanceKey;
// Define the notification name
NSString * const kPrefsChangedNotification = @"PrefsChangedNotification";


@interface PreferencesViewController ()
// UI Element Properties
@property (nonatomic, strong) NSTextField *widthTextField;
@property (nonatomic, strong) NSTextField *heightTextField;
@property (nonatomic, strong) NSPopUpButton *appearancePopUpButton;
@property (nonatomic, strong) NSButton *applyButton;
@end

@implementation PreferencesViewController

- (void)loadView {
    // Create a container view - Increased height for Apply button
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 180)]; // Increased height
    view.wantsLayer = YES;

    // --- Width ---
    NSTextField *widthLabel = [self createLabel:@"Width:" frame:NSMakeRect(20, 140, 80, 17)]; // Adjusted Y
    self.widthTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(110, 138, 100, 22)]; // Adjusted Y

    // --- Height ---
    NSTextField *heightLabel = [self createLabel:@"Height:" frame:NSMakeRect(20, 105, 80, 17)]; // Adjusted Y
    self.heightTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(110, 103, 100, 22)]; // Adjusted Y

    // --- Appearance ---
    NSTextField *appearanceLabel = [self createLabel:@"Appearance:" frame:NSMakeRect(20, 70, 80, 17)]; // Adjusted Y
    self.appearancePopUpButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(110, 68, 150, 25) pullsDown:NO]; // Adjusted Y
    [self.appearancePopUpButton addItemsWithTitles:@[@"System", @"Light", @"Dark"]];

    // --- Apply Button --- Changed to OK Button ---
    // Renamed title and action selector
    self.applyButton = [NSButton buttonWithTitle:@"OK" target:self action:@selector(okAction:)];
    [self.applyButton setButtonType:NSButtonTypeMomentaryPushIn];
    [self.applyButton setBezelStyle:NSBezelStyleRounded];
    // Make this the default button (responds to Enter key)
    self.applyButton.keyEquivalent = @"\r";
    self.applyButton.frame = NSMakeRect(200, 20, 80, 24); // Positioned at bottom right

    // Add controls to the view
    [view addSubview:widthLabel];
    [view addSubview:self.widthTextField];
    [view addSubview:heightLabel];
    [view addSubview:self.heightTextField];
    [view addSubview:appearanceLabel];
    [view addSubview:self.appearancePopUpButton];
    [view addSubview:self.applyButton]; // Add the new button

    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Load current settings when the view loads initially
    [self loadPreferences];
}

// Helper to create labels
- (NSTextField *)createLabel:(NSString *)text frame:(NSRect)frame {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:text];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setAlignment:NSTextAlignmentRight];
    return label;
}

// Load settings from UserDefaults into UI controls
- (void)loadPreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.widthTextField.integerValue = [defaults integerForKey:kPrefWidthKey];
    self.heightTextField.integerValue = [defaults integerForKey:kPrefHeightKey];

    NSInteger appearanceSetting = [defaults integerForKey:kPrefAppearanceKey];
    [self.appearancePopUpButton selectItemAtIndex:appearanceSetting]; // Index matches our constants (0, 1, 2)
}

// Action called only when OK button is clicked
// Renamed from applyChanges: to okAction:
- (IBAction)okAction:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Save width and height (add validation if needed)
    [defaults setInteger:self.widthTextField.integerValue forKey:kPrefWidthKey];
    [defaults setInteger:self.heightTextField.integerValue forKey:kPrefHeightKey];

    // Save appearance
    [defaults setInteger:self.appearancePopUpButton.indexOfSelectedItem forKey:kPrefAppearanceKey];

    // Post a notification so other parts of the app can react
    [[NSNotificationCenter defaultCenter] postNotificationName:kPrefsChangedNotification object:self];
    NSLog(@"[PreferencesVC] OK button clicked, changes saved and notification posted."); // Log confirmation

    // Close the window containing this view controller
    [self.view.window close];
}

@end 
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
@end

@implementation PreferencesViewController

- (void)loadView {
    // Create a container view
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 150)]; // Adjust size as needed
    view.wantsLayer = YES;

    // --- Width ---
    NSTextField *widthLabel = [self createLabel:@"Width:" frame:NSMakeRect(20, 110, 80, 17)];
    self.widthTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(110, 108, 100, 22)];
    self.widthTextField.target = self;
    self.widthTextField.action = @selector(prefChanged:); // Action for text field changes

    // --- Height ---
    NSTextField *heightLabel = [self createLabel:@"Height:" frame:NSMakeRect(20, 75, 80, 17)];
    self.heightTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(110, 73, 100, 22)];
    self.heightTextField.target = self;
    self.heightTextField.action = @selector(prefChanged:);

    // --- Appearance ---
    NSTextField *appearanceLabel = [self createLabel:@"Appearance:" frame:NSMakeRect(20, 40, 80, 17)];
    self.appearancePopUpButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(110, 38, 150, 25) pullsDown:NO];
    [self.appearancePopUpButton addItemsWithTitles:@[@"System", @"Light", @"Dark"]];
    self.appearancePopUpButton.target = self;
    self.appearancePopUpButton.action = @selector(prefChanged:);

    // Add controls to the view
    [view addSubview:widthLabel];
    [view addSubview:self.widthTextField];
    [view addSubview:heightLabel];
    [view addSubview:self.heightTextField];
    [view addSubview:appearanceLabel];
    [view addSubview:self.appearancePopUpButton];

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

// Action called when any preference control changes value
- (IBAction)prefChanged:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Save width and height (add validation if needed)
    [defaults setInteger:self.widthTextField.integerValue forKey:kPrefWidthKey];
    [defaults setInteger:self.heightTextField.integerValue forKey:kPrefHeightKey];

    // Save appearance
    [defaults setInteger:self.appearancePopUpButton.indexOfSelectedItem forKey:kPrefAppearanceKey];

    // Post a notification so other parts of the app can react
    [[NSNotificationCenter defaultCenter] postNotificationName:kPrefsChangedNotification object:self];

    // Optional: Synchronize immediately (often not needed, system does it periodically)
    // [defaults synchronize];
}

@end 
#import <Preferences/Preferences.h>
#import "ColorPicker/HRColorPickerView.h"
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import <AddressBook/AddressBook.h>
#import <objc/runtime.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+ImageEffects.h"
#import "CustomCells.h"
#import "CustomControllers.h"
#import "CircleViews.h"
#import "StaticFunctions.h"

NSInteger system_nd(const char* command) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    return system(command);
#pragma GCC diagnostic pop
}

#define CURRENT_TWEAK_VERSION @"1.3.0"
#define TINT_COLOUR [UIColor colorWithRed:249.0/255.0 green:103.0/255.0 blue:30.0/255.0 alpha:1]
#define listPath @"/var/lib/dpkg/info/me.chewitt.mcpro.list"

__attribute__((always_inline)) static BOOL wenge() {
    return [[NSFileManager defaultManager] fileExistsAtPath:listPath];
}

static BOOL iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
static BOOL is_IOS_8 = [[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending;
NSString* themeNameForEdit;
NSString* activeThemePath;
NSString* activeThemeName;
NSString* activeThemePathNoPlist;
NSString* baseThemeForNewThemeName;
NSMutableArray* directoryList;
NSMutableArray* directoryTitlesList;
extern NSString* PSDeletionActionKey;
UIColor* defaultAppTint;
UIColor* defaultBarTint;
static NSArray* defaultThemeNames = [NSArray arrayWithObjects:@"Dark", @"Fade", @"Flat", @"Outlines", @"Translucent", @"Translucent Dark", nil];

static void updateDirectoryList() {
    NSString* documentsDirectory = @"/var/mobile/Library/MCPro/Themes";
    NSFileManager* fM = [NSFileManager defaultManager];
    NSArray* fileList = [fM contentsOfDirectoryAtPath:documentsDirectory error:nil];
    directoryList = [[NSMutableArray alloc] init];
    directoryTitlesList = [NSMutableArray array];
    for (NSString* file in fileList) {
        NSString* path = [documentsDirectory stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        BOOL fileExists = [fM fileExistsAtPath:path isDirectory:(&isDir)];
        if (isDir && ! [file isEqual:@".AppleDouble"] && fileExists) {
            [directoryList addObject:file];
            if ([file isEqualToString:@"Default"]) {
                [directoryTitlesList addObject:localisedStringForKey(@"DEFAULT")];
            }
            else {
                [directoryTitlesList addObject:[file stringByReplacingOccurrencesOfString:@"_" withString:@" "]];
            }
        }
    }
}

static void ensureThemeForEditIsValid() {
    NSString* path = @"var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist";
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (! themeNameForEdit) {
        themeNameForEdit = [dic valueForKey:@"LastEditedTheme"];
    }
    else {
        [dic setValue:themeNameForEdit forKey:@"LastEditedTheme"];
        [dic writeToFile:path atomically:YES];
    }
    activeThemePath = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/Theme.plist", themeNameForEdit];
    activeThemeName = themeNameForEdit;
    activeThemePathNoPlist = [activeThemePath stringByDeletingPathExtension];

    if (! [[NSFileManager defaultManager] fileExistsAtPath:activeThemePath]) {
        NSString* path = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@", themeNameForEdit];
        NSString* mkdir = [NSString stringWithFormat:@"mkdir %@", path];
        system_nd([mkdir UTF8String]);
        NSString* defaultDir = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/Theme.plist", baseThemeForNewThemeName];
        NSData* myData = [[NSFileManager defaultManager] contentsAtPath:defaultDir];
        [myData writeToFile:activeThemePath atomically:YES];
    }
}

static CFMutableArrayRef getSortedListOfContacts() {
    CFErrorRef* error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
            kCFAllocatorDefault,
            numberOfPeople,
            allPeople
            );
    CFArraySortValues(
        peopleMutable,
        CFRangeMake(0, CFArrayGetCount(peopleMutable)),
        (CFComparatorFunction)ABPersonComparePeopleByName,
        (void*)(unsigned long)ABPersonGetSortOrdering()
        );
    return peopleMutable;
}

@interface CHUIImagePickerController:UIImagePickerController
@end

@implementation CHUIImagePickerController

-(NSUInteger) supportedInterfaceOrientations {
    if (iPad) {
        return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
    }
    else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end

CHMCThemeListItemCell* defaultCell;
PSListController* activeThemeSelectionController;
CHMCBackgroundImageViewCell* activeCHMCBackgroundImageViewCell;
CHMCDatePickerViewCell* activeToCell;
CHMCDatePickerViewCell* activeFromCell;
BOOL isSettingTo;
NSString* activeContactName;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define prefsPath @"/User/Library/Preferences"

@implementation CHMCPPSListController

-(void) setTitle:(id)arg1 {
    [super setTitle:localisedStringForKey(arg1)];
}

-(id) loadSpecifiersFromPlistName:(NSString*)plist target:(id)target {
    NSArray* specs = [super loadSpecifiersFromPlistName:plist target:target];
    for (PSSpecifier* s in specs) {
        s.name = localisedStringForKey(s.name);
        [s setProperty:localisedStringForKey([s propertyForKey:@"footerText"]) forKey:@"footerText"];
    }
    return specs;
}

-(void) viewWillAppear:(BOOL)anim {
    [super viewWillAppear:anim];
    if (! defaultAppTint) {
        defaultAppTint = [UIApplication sharedApplication].keyWindow.tintColor;
    }
    if (! defaultBarTint) {
        defaultBarTint = self.navigationController.navigationBar.tintColor;
    }

    self.navigationController.navigationBar.tintColor = TINT_COLOUR;
    self.view.tintColor = TINT_COLOUR;
    [UIApplication sharedApplication].keyWindow.tintColor = TINT_COLOUR;
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
    NSString* path = nil;
    if ([specifier.properties[@"defaults"] hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"%@.plist", specifier.properties[@"defaults"]];
    }
    else {
        path = [NSString stringWithFormat:@"%@/%@.plist", prefsPath, specifier.properties[@"defaults"]];
    }
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:path];
    id val;
    if (! dic[specifier.properties[@"key"]]) {
        val = specifier.properties[@"default"];
    }
    else {
        val = dic[specifier.properties[@"key"]];
    }
    if ([specifier.properties[@"negate"] boolValue]) {
        val = [NSNumber numberWithInt:(NSInteger) ! [val boolValue]];
    }
    return val;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
    NSString* path = nil;
    if ([specifier.properties[@"defaults"] hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"%@.plist", specifier.properties[@"defaults"]];
    }
    else {
        path = [NSString stringWithFormat:@"%@/%@.plist", prefsPath, specifier.properties[@"defaults"]];
    }
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    if ([specifier.properties[@"negate"] boolValue]) {
        [defaults setObject:[NSNumber numberWithInt:(NSInteger) ! [value boolValue]] forKey:specifier.properties[@"key"]];
    }
    else {
        [defaults setObject:value forKey:specifier.properties[@"key"]];
    }
    [defaults writeToFile:path atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

@end

NSMutableArray* nonEditableCells = [NSMutableArray array];

@implementation CHMCPPSEditableListController

-(void) viewWillAppear:(BOOL)anim {
    [super viewWillAppear:anim];
    self.navigationController.navigationBar.tintColor = TINT_COLOUR;
    self.view.tintColor = TINT_COLOUR;
    [UIApplication sharedApplication].keyWindow.tintColor = TINT_COLOUR;
}

-(UITableViewCellEditingStyle) tableView:(UITableView*)aTableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    for (UITableViewCell* c in nonEditableCells) {
        if ([indexPath isEqual:[aTableView indexPathForCell:c]]) {
            return UITableViewCellEditingStyleNone;
        }
    }
    return UITableViewCellEditingStyleDelete;
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
    NSString* path = nil;
    if ([specifier.properties[@"defaults"] hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"%@.plist", specifier.properties[@"defaults"]];
    }
    else {
        path = [NSString stringWithFormat:@"%@/%@.plist", prefsPath, specifier.properties[@"defaults"]];
    }
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:path];
    id val;
    if (! dic[specifier.properties[@"key"]]) {
        val = specifier.properties[@"default"];
    }
    else {
        val = dic[specifier.properties[@"key"]];
    }

    if ([specifier.properties[@"negate"] boolValue]) {
        val = [NSNumber numberWithInt:(NSInteger) ! [val boolValue]];
    }

    return val;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
    NSString* path = nil;
    if ([specifier.properties[@"defaults"] hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"%@.plist", specifier.properties[@"defaults"]];
    }
    else {
        path = [NSString stringWithFormat:@"%@/%@.plist", prefsPath, specifier.properties[@"defaults"]];
    }
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    if ([specifier.properties[@"negate"] boolValue]) {
        [defaults setObject:[NSNumber numberWithInt:(NSInteger) ! [value boolValue]] forKey:specifier.properties[@"key"]];
    }
    else {
        [defaults setObject:value forKey:specifier.properties[@"key"]];
    }
    [defaults writeToFile:path atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

@end

@implementation CHMCPPSListItemsController

-(void) viewWillAppear:(BOOL)anim {
    [super viewWillAppear:anim];
    self.navigationController.navigationBar.tintColor = TINT_COLOUR;
    self.view.tintColor = TINT_COLOUR;
    [UIApplication sharedApplication].keyWindow.tintColor = TINT_COLOUR;
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
    NSString* path = nil;
    if ([specifier.properties[@"defaults"] hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"%@.plist", specifier.properties[@"defaults"]];
    }
    else {
        path = [NSString stringWithFormat:@"%@/%@.plist", prefsPath, specifier.properties[@"defaults"]];
    }
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:path];
    id val;
    if (! dic[specifier.properties[@"key"]]) {
        val = specifier.properties[@"default"];
    }
    else {
        val = dic[specifier.properties[@"key"]];
    }

    if ([specifier.properties[@"negate"] boolValue]) {
        val = [NSNumber numberWithInt:(NSInteger) ! [val boolValue]];
    }

    return val;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
    NSString* path = nil;
    if ([specifier.properties[@"defaults"] hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"%@.plist", specifier.properties[@"defaults"]];
    }
    else {
        path = [NSString stringWithFormat:@"%@/%@.plist", prefsPath, specifier.properties[@"defaults"]];
    }
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    if ([specifier.properties[@"negate"] boolValue]) {
        [defaults setObject:[NSNumber numberWithInt:(NSInteger) ! [value boolValue]] forKey:specifier.properties[@"key"]];
    }
    else {
        [defaults setObject:value forKey:specifier.properties[@"key"]];
    }
    [defaults writeToFile:path atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

@end

@implementation CHMCThemeMakerController

-(id) specifiers {
    if (_specifiers == nil) {
        ensureThemeForEditIsValid();
        themeName = activeThemeName;

        _specifiers = [self loadSpecifiersFromPlistName:@"NewTheme" target:self];
        self.title = [NSString stringWithFormat:@"%@ %@", localisedStringForKey(@"EDITING"), [themeName stringByReplacingOccurrencesOfString:@"_" withString:@" "]];

        for (PSSpecifier* s in _specifiers) {
            [s setProperty:activeThemePathNoPlist forKey:@"defaults"];
        }

        [self setPreferenceValue:[themeName stringByReplacingOccurrencesOfString:@"_" withString:@" "] specifier:[self specifierForID:@"themeName"]];
    }
    return _specifiers;
}

-(void) reloadInfo {
    [self setPreferenceValue:[themeName stringByReplacingOccurrencesOfString:@"_" withString:@" "] specifier:[self specifierForID:@"themeName"]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reloadSpecifiers];
}

-(void) changeThemeName {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"THEME_NAME")
                          message:localisedStringForKey(@"THEME_NAME_ALERT_TEXT")
                          delegate:self
                          cancelButtonTitle:localisedStringForKey(@"CANCEL")
                          otherButtonTitles:localisedStringForKey(@"ENTER")
                          , nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    [[alert textFieldAtIndex:0] setDelegate:self];
    [[alert textFieldAtIndex:0] resignFirstResponder];
    [alert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [[alert textFieldAtIndex:0] becomeFirstResponder];
    alert.tag = 84758;
}

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1 && alertView.tag == 84758) {
        NSString* newName = [alertView textFieldAtIndex:0].text;
        [[alertView textFieldAtIndex:0] resignFirstResponder];
        newName = [newName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_-]+" options:0 error:nil];
        newName = [regex stringByReplacingMatchesInString:newName options:0 range:NSMakeRange(0, newName.length) withTemplate:@""];

        if ([directoryList containsObject:newName]) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERROR")
                                  message:localisedStringForKey(@"THEME_NAME_ERROR_TEXT")
                                  delegate:self
                                  cancelButtonTitle:localisedStringForKey(@"OK")
                                  otherButtonTitles:nil];
            alert.tag = 8283274;
            [alert show];
        }
        else {
            NSString* oldThemeName = themeName;
            themeNameForEdit = newName;
            themeName = themeNameForEdit;

            [self setPreferenceValue:[themeName stringByReplacingOccurrencesOfString:@"_" withString:@" "] specifier:[self specifierForID:@"themeName"]];
            [[NSUserDefaults standardUserDefaults] synchronize];

            NSString* oldThemePath = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@", activeThemeName];
            NSString* newPath = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@", themeName];

            NSString* mv = [NSString stringWithFormat:@"mv %@ %@", oldThemePath, newPath];
            system_nd([mv UTF8String]);

            pathToTheme = [NSString stringWithFormat:@"%@/Theme.plist", newPath];

            [self reloadSpecifiers];

            NSString* activeTheme = [self readPreferenceValue:[(PSListController*)_parentController specifierForID:@"themeSelect"]];
            if ([oldThemeName isEqual:activeTheme]) {
                [self setPreferenceValue:themeName specifier:[(PSListController*)_parentController specifierForID:@"themeSelect"]];
            }
        }
    }
    else if (alertView.tag == 8283274) {
        [self changeThemeName];
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadInfo];
}

@end

@implementation MCProPrefsListController

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkForPermaPlist];
    [self reloadSpecifiers];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.tintColor = defaultBarTint;
    [UIApplication sharedApplication].keyWindow.tintColor = defaultBarTint;
}

-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"MCProPrefs" target:self];
        UIBarButtonItem* likeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MCProPrefs.bundle/heart.png"] style:UIBarButtonItemStylePlain target:self action:@selector(composeTweet)];
        ((UINavigationItem*)self.navigationItem).rightBarButtonItem = likeButton;
        PSSpecifier* newSpecifier = [self specifierForID:@"newTheme"];
        [newSpecifier setButtonAction:@selector(chooseNewThemeName)];
        PSSpecifier* editSpecifier = [self specifierForID:@"editTheme"];
        [editSpecifier setButtonAction:@selector(chooseThemeToEdit)];

        PSSpecifier* copyright = [self specifierForID:@"copyright"];
        NSString* footer = [copyright propertyForKey:@"footerText"];
        if (! wenge()) {
            footer = [footer stringByReplacingOccurrencesOfString:@"$" withString:[NSString stringWithFormat:@"%@ ☠", CURRENT_TWEAK_VERSION]];
        }
        else {
            footer = [footer stringByReplacingOccurrencesOfString:@"$" withString:CURRENT_TWEAK_VERSION];
        }
        [copyright setProperty:footer forKey:@"footerText"];

        PSSpecifier* supportGroup = [self specifierForID:@"supportGroup"];
        if (! wenge()) {
            [supportGroup setProperty:@"If you like M.C. Pro, please consider supporting future development by purchasing." forKey:@"footerText"];
        }
    }

    updateDirectoryList();

    PSSpecifier* themeSelect = [self specifierForID:@"themeSelect"];
    [themeSelect setValues:directoryList titles:directoryTitlesList];

    return _specifiers;
}

-(void) composeTweet {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController* tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:localisedStringForKey(@"TWEET")];
        UIViewController* rootViewController = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:tweetSheet animated:YES completion:nil];
    }
    else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERROR")
                              message:localisedStringForKey(@"TWEET_ERROR_MESSAGE")
                              delegate:self
                              cancelButtonTitle:localisedStringForKey(@"OK")
                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void) openEmailLink {
    NSString* currSysVer = [[UIDevice currentDevice] systemVersion];
    NSString* tweakVer = CURRENT_TWEAK_VERSION;
    if (! wenge()) {
        tweakVer = [tweakVer stringByAppendingString:@"."];
    }
    NSString* device = machineName();

    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker setSubject:[NSString stringWithFormat:@"M.C. Pro %@ - %@ : %@", tweakVer, device, currSysVer]];

        NSArray* toRecipients = [NSArray arrayWithObject:@"contact@chewitt.me"];
        [picker setToRecipients:toRecipients];

        UIViewController* rootViewController = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:picker animated:YES completion:NULL];
    }
    else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERROR")
                              message:localisedStringForKey(@"MAIL_ERROR_MESSAGE")
                              delegate:self
                              cancelButtonTitle:localisedStringForKey(@"OK")
                              otherButtonTitles:nil
                              , nil];
        [alert show];
    }
}

-(void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

-(void) openTwitterLink {
    NSURL* appURL = [NSURL URLWithString:@"twitter:///user?screen_name=friggog"];
    if ([[UIApplication sharedApplication] canOpenURL:appURL]) {
        [[UIApplication sharedApplication] openURL:appURL];
    }
    else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/friggog"]];
    }
}

-(void) chooseNewThemeName {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"THEME_NAME")
                          message:localisedStringForKey(@"ENTER_THEME_NAME_TEXT")
                          delegate:self
                          cancelButtonTitle:localisedStringForKey(@"CANCEL")
                          otherButtonTitles:localisedStringForKey(@"ENTER")
                          , nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    [[alert textFieldAtIndex:0] setDelegate:self];
    [[alert textFieldAtIndex:0] resignFirstResponder];
    [alert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [[alert textFieldAtIndex:0] becomeFirstResponder];
    alert.tag = 1111;
}

-(void) chooseThemeToEdit {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:localisedStringForKey(@"THEME_EDIT_ALERT_TITLE")
                                  delegate:self
                                  cancelButtonTitle:nil
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:nil];

    themeListMinusDefault = [NSMutableArray arrayWithArray:directoryTitlesList];
    [themeListMinusDefault removeObject:localisedStringForKey(@"DEFAULT")];
    for (NSString* t in defaultThemeNames) {
        [themeListMinusDefault removeObject:t];
    }

    for (NSString* t in themeListMinusDefault) {
        [actionSheet addButtonWithTitle:t];
    }

    [actionSheet addButtonWithTitle:localisedStringForKey(@"CANCEL")];
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;

    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

-(void) actionSheet:(UIActionSheet*)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (popup.tag == 893234) {
        baseThemeForNewThemeName = [[directoryTitlesList objectAtIndex:buttonIndex] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            PSSpecifier* newSpecifier = [[self loadSpecifiersFromPlistName:@"MCProPrefs" target:self] objectAtIndex:8];
        [self pushController:[self controllerForSpecifier:newSpecifier]];
    }
    else {
        if (buttonIndex < popup.numberOfButtons -1) {
            themeNameForEdit = [[themeListMinusDefault objectAtIndex:buttonIndex] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            PSSpecifier* editSpecifier = [[self loadSpecifiersFromPlistName:@"MCProPrefs" target:self] objectAtIndex:9];
            [self pushController:[self controllerForSpecifier:editSpecifier]];
        }
    }
}

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1 && alertView.tag == 1111) {
        themeNameForEdit = [alertView textFieldAtIndex:0].text;
        [[alertView textFieldAtIndex:0] resignFirstResponder];
        themeNameForEdit = [themeNameForEdit stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_-]+" options:0 error:nil];
        themeNameForEdit = [regex stringByReplacingMatchesInString:themeNameForEdit options:0 range:NSMakeRange(0, themeNameForEdit.length) withTemplate:@""];

        if ([directoryList containsObject:themeNameForEdit]) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERROR")
                                  message:localisedStringForKey(@"THEME_NAME_ERROR_TEXT")
                                  delegate:self
                                  cancelButtonTitle:localisedStringForKey(@"OK")
                                  otherButtonTitles:nil];
            alert.tag = 2222;
            [alert show];
        }
        else {
            UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:localisedStringForKey(@"BASE_FOR_NEW_THEME")
                                          delegate:self
                                          cancelButtonTitle:nil
                                          destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
            for (NSString* t in directoryTitlesList) {
                [actionSheet addButtonWithTitle:t];
            }
            actionSheet.tag = 893234;
            [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
        }
    }
    else if (alertView.tag == 2222) {
        [self chooseNewThemeName];
    }
}

-(void) checkForPermaPlist {
    NSString* path = @"var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist";
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (! dic) {
        dic = [[NSMutableDictionary alloc] init];
        [dic setValue:@"#FF007A" forKey:@"AppTint"];
        [dic setValue:@"#222222" forKey:@"CustomDMBackgroundColour"];
        [dic setValue:@"#cccccc" forKey:@"CustomDMForegroundColour"];
        [dic setValue:@"#FFFFFF" forKey:@"CustomDMBrightColour"];
        [dic setValue:@"08:00" forKey:@"DarkModeScheduleToTime"];
        [dic setValue:@"22:00" forKey:@"DarkModeScheduleFromTime"];
        [dic writeToFile:path atomically:YES];
    }
}

@end

@implementation CHMCConvosThemesController

-(void) viewWillAppear:(BOOL)arg1 {
    [super viewWillAppear:arg1];
    [self reloadSpecifiers];
}

-(id) specifiers {
    if (_specifiers == nil) {
        updateDirectoryList();

        NSMutableArray* a = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"ConvosPrefs" target:self]];

        MCProPrefsListController* pc = (MCProPrefsListController*)_parentController;
        fallbackTheme = [pc readPreferenceValue:[pc specifierForID:@"themeSelect"]];

        PSSpecifier* groupSpec = [a objectAtIndex:0];
        [groupSpec setValues:directoryList titles:directoryTitlesList];
        [groupSpec setProperty:fallbackTheme forKey:@"default"];
        [groupSpec setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MCProPrefs.bundle/group.png"] forKey:@"iconImage"];

        CFMutableArrayRef contactList = getSortedListOfContacts();
        if (CFArrayGetCount(contactList) > 0) {
            for (NSInteger i = 0; i < CFArrayGetCount(contactList); i++) {
                ABRecordRef person = CFArrayGetValueAtIndex(contactList, i);
                NSString* firstName = (__bridge NSString*)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
                NSString* lastName = (__bridge NSString*)(ABRecordCopyValue(person, kABPersonLastNameProperty));

                NSString* fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                if (! firstName) {
                    fullName = lastName;
                }
                if (! lastName) {
                    fullName = firstName;
                }

                PSSpecifier* spec = [[self loadSpecifiersFromPlistName:@"ConvosPrefs" target:self] objectAtIndex:0];

                UIImage* contactPic;
                if (ABPersonHasImageData(person)) {
                    CFDataRef cfData = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
                    NSData* data = (__bridge_transfer NSData*)cfData;
                    UIImage* img = [UIImage imageWithData:data];
                    contactPic = [img scaledToSize:CGSizeMake(29, (29/img.size.width) * img.size.height)];
                    contactPic = [contactPic roundImageInFrame:CGRectMake(0, 0, 29, 29)];
                }
                else {
                    contactPic = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MCProPrefs.bundle/contact.png"];
                }

                [spec setName:fullName];
                [spec setProperty:fullName forKey:@"key"];
                [spec setProperty:fallbackTheme forKey:@"default"];
                [spec setValues:directoryList titles:directoryTitlesList];
                [spec setProperty:contactPic forKey:@"iconImage"];
                [a addObject:spec];
            }
        }

        PSSpecifier* group = [PSSpecifier preferenceSpecifierNamed:@""
                              target:self
                              set:nil
                              get:nil
                              detail:nil
                              cell:[PSTableCell cellTypeFromString:@"PSGroupCell"]
                              edit:0];
        [a addObject:group];

        PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:localisedStringForKey(@"ERASE_CONVOS_INFO")
                             target:self
                             set:nil
                             get:nil
                             detail:nil
                             cell:[PSTableCell cellTypeFromString:@"PSButtonCell"]
                             edit:0];
        [spec setProperty:[PSDeleteTableCell class] forKey:@"cellClass"];
        [spec setButtonAction:@selector(eraseAllInfo)];
        [a addObject:spec];

        _specifiers = [NSArray arrayWithArray:a];
    }
    return _specifiers;
}

-(void) eraseAllInfo {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERASE_CONVOS_INFO")
                          message:localisedStringForKey(@"ERASE_CONVOS_INFO_ALERT_MESSAGE")
                          delegate:self
                          cancelButtonTitle:localisedStringForKey(@"NO")
                          otherButtonTitles:localisedStringForKey(@"YES")
                          , nil];
    [alert show];
}

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [NSUserDefaults resetStandardUserDefaults];
        NSString* pathToPlist = @"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.convos.plist";
        NSData* blank = [[NSData alloc] init];
        [blank writeToFile:pathToPlist atomically:YES];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reloadSpecifiers];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.chewitt.mcproprefs.settingsChanged"), nil, nil, true);
    }
}

@end

@implementation CHMCContactsThemesController

-(void) viewWillAppear:(BOOL)arg1 {
    [super viewWillAppear:arg1];
    [self reloadSpecifiers];
}

-(id) specifiers {
    if (_specifiers == nil) {
        CFMutableArrayRef contactList = getSortedListOfContacts();

        NSMutableArray* a = [NSMutableArray  array];
        if (CFArrayGetCount(contactList) > 0) {
            for (NSInteger i = 0; i < CFArrayGetCount(contactList); i++) {
                ABRecordRef person = CFArrayGetValueAtIndex(contactList, i);
                NSString* firstName = (__bridge NSString*)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
                NSString* lastName = (__bridge NSString*)(ABRecordCopyValue(person, kABPersonLastNameProperty));

                NSString* fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                if (! firstName) {
                    fullName = lastName;
                }
                if (! lastName) {
                    fullName = firstName;
                }

                UIImage* contactPic;
                if (ABPersonHasImageData(person)) {
                    CFDataRef cfData = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
                    NSData* data = (__bridge_transfer NSData*)cfData;
                    UIImage* img = [UIImage imageWithData:data];
                    contactPic = [img scaledToSize:CGSizeMake(29, (29/img.size.width) * img.size.height)];
                    contactPic = [contactPic roundImageInFrame:CGRectMake(0, 0, 29, 29)];
                    CFRelease(cfData);
                }
                else {
                    contactPic = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MCProPrefs.bundle/contact.png"];
                }

                PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:fullName
                                     target:self
                                     set:nil
                                     get:nil
                                     detail:[CHMCContactBubbleColourController class]
                                     cell:[PSTableCell cellTypeFromString:@"PSLinkCell"]
                                     edit:0];
                [spec setProperty:[CHMCContactLinkCellWithColours class] forKey:@"cellClass"];
                [spec setProperty:contactPic forKey:@"iconImage"];
                [a addObject:spec];
            }
        }

        PSSpecifier* group = [PSSpecifier preferenceSpecifierNamed:@""
                              target:self
                              set:nil
                              get:nil
                              detail:nil
                              cell:[PSTableCell cellTypeFromString:@"PSGroupCell"]
                              edit:0];
        [a addObject:group];

        PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:localisedStringForKey(@"ERASE_CONTACTS_INFO")
                             target:self
                             set:nil
                             get:nil
                             detail:nil
                             cell:[PSTableCell cellTypeFromString:@"PSButtonCell"]
                             edit:0];
        [spec setProperty:[PSDeleteTableCell class] forKey:@"cellClass"];
        [spec setButtonAction:@selector(eraseAllInfo)];
        [a addObject:spec];

        _specifiers = [NSArray arrayWithArray:a];
    }
    return _specifiers;
}

-(void) eraseAllInfo {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERASE_CONTACTS_INFO")
                          message:localisedStringForKey(@"ERASE_CONTACTS_INFO_ALERT_MESSAGE")
                          delegate:self
                          cancelButtonTitle:localisedStringForKey(@"NO")
                          otherButtonTitles:localisedStringForKey(@"YES")
                          , nil];
    [alert show];
}

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [NSUserDefaults resetStandardUserDefaults];
        NSString* pathToPlist = @"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.contacts.plist";
        NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
        [dic writeToFile:pathToPlist atomically:YES];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reloadSpecifiers];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.chewitt.mcproprefs.settingsChanged"), nil, nil, true);
    }
}

@end

@implementation CHMCThemeSelectionController

-(id) specifiers {
    activeThemeSelectionController = self;
    if (_specifiers == nil) {
        updateDirectoryList();

        NSMutableArray* a = [NSMutableArray array];

        for (NSString* s in directoryTitlesList) {
            PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:s
                                 target:self
                                 set:nil
                                 get:nil
                                 detail:nil
                                 cell:[PSTableCell cellTypeFromString:@"PSListItemCell"]
                                 edit:0];
            [spec setProperty:NSStringFromSelector(@selector(removedSpecifier:)) forKey:PSDeletionActionKey];
            [spec setProperty:[CHMCThemeListItemCell class] forKey:@"cellClass"];
            [a addObject:spec];
        }

        _specifiers = [NSArray arrayWithArray:a];
    }
    return _specifiers;
}

-(void) removedSpecifier:(PSSpecifier*)specifier {
    NSString* activeTheme = [self readPreferenceValue:self.specifier];
    NSString* name = [specifier.name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([name isEqualToString:activeTheme]) {
        [self setPreferenceValue:@"Default" specifier:self.specifier];
        [defaultCell setChecked:YES];
    }
    NSString* path = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@", name];
    NSString* com = [NSString stringWithFormat:@"rm -rf %@", path];
    system_nd([com UTF8String]);

    [NSUserDefaults resetStandardUserDefaults];
    NSString* pathToPlist = @"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.convos.plist";
    NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:pathToPlist];
    for (NSString* key in [plist allKeys]) {
        if ([[plist valueForKey:key] isEqualToString:specifier.name]) {
            [plist removeObjectForKey:key];
        }
    }
    [plist writeToFile:pathToPlist atomically:YES];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

@implementation CHMCConvoSpecificThemeSelectionController

-(id) specifiers {
    activeThemeSelectionController = self;
    if (_specifiers == nil) {
        NSMutableArray* a = [NSMutableArray array];

        for (NSString* s in self.specifier.values) {
            PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:[self.specifier.titleDictionary valueForKey:s]
                                 target:self
                                 set:nil
                                 get:nil
                                 detail:nil
                                 cell:[PSTableCell cellTypeFromString:@"PSListItemCell"]
                                 edit:0];
            [spec setProperty:[CHMCThemeListItemCell class] forKey:@"cellClass"];
            [a addObject:spec];
        }

        PSSpecifier* group = [PSSpecifier preferenceSpecifierNamed:@""
                              target:self
                              set:nil
                              get:nil
                              detail:nil
                              cell:[PSTableCell cellTypeFromString:@"PSGroupCell"]
                              edit:0];
        [a addObject:group];

        PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:localisedStringForKey(@"ERASE_CONVO_INFO")
                             target:self
                             set:nil
                             get:nil
                             detail:nil
                             cell:[PSTableCell cellTypeFromString:@"PSButtonCell"]
                             edit:0];
        [spec setButtonAction:@selector(eraseInfo)];
        [spec setProperty:[PSDeleteTableCell class] forKey:@"cellClass"];
        [a addObject:spec];

        _specifiers = [NSArray arrayWithArray:a];
    }
    return _specifiers;
}

-(void) eraseInfo {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERASE_CONVO_INFO")
                          message:localisedStringForKey(@"ERASE_CONVO_INFO_ALERT_MESSAGE")
                          delegate:self
                          cancelButtonTitle:localisedStringForKey(@"NO")
                          otherButtonTitles:localisedStringForKey(@"YES")
                          , nil];
    [alert show];
}

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [NSUserDefaults resetStandardUserDefaults];
        NSString* pathToPlist = @"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.convos.plist";
        NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:pathToPlist];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@", self.specifier.name]];
        [plist writeToFile:pathToPlist atomically:YES];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reloadSpecifiers];
        [(PSListController*)_parentController reloadSpecifiers];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.chewitt.mcproprefs.settingsChanged"), nil, nil, true);
    }
}

@end

@implementation CHMCBubbleController

-(id) specifiers {
    self.title = self.specifier.name;
    if (_specifiers == nil) {
        [self setStrings];
        if (! [self isKindOfClass:[CHMCContactBubbleColourController class]]) {
            ensureThemeForEditIsValid();
        }

        _specifiers = [self loadSpecifiersFromPlistName:plistName target:self];

        for (PSSpecifier* s in _specifiers) {
            [s setProperty:activeThemePathNoPlist forKey:@"defaults"];
        }

        [[NSUserDefaults standardUserDefaults] synchronize];

        BOOL gradient = [[self readPreferenceValue:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"gradient"]]] boolValue];

        NSMutableArray* a = [[NSMutableArray alloc] init];
        for (PSSpecifier* s in _specifiers) {
            if (gradient) {
                if (! [s.identifier isEqualToString:@"SingleBubbleColour"]) {
                    [a addObject:s];
                }
            }
            else {
                if (! [s.identifier isEqualToString:@"TopBubbleColour"] && ! [s.identifier isEqualToString:@"BottomBubbleColour"]) {
                    [a addObject:s];
                }
            }
        }
        _specifiers = a;
    }
    return _specifiers;
}

-(void) setStrings {
    plistName = @"";
}

-(void) setGradient:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    id prefs = [self loadSpecifiersFromPlistName:plistName target:self];
    if ([value boolValue]) {
        [self removeSpecifierAtIndex:3 animated:YES];
        [self insertSpecifier:[prefs objectAtIndex:3] afterSpecifier:[_specifiers objectAtIndex:2] animated:YES];
        [self insertSpecifier:[prefs objectAtIndex:4] afterSpecifier:[_specifiers objectAtIndex:3] animated:YES];
    }
    else {
        [self removeSpecifierAtIndex:3 animated:YES];
        [self removeSpecifierAtIndex:3 animated:YES];
        [self insertSpecifier:[prefs objectAtIndex:2] afterSpecifier:[_specifiers objectAtIndex:2] animated:YES];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

+(NSArray*) currentColours {
    return nil;
}

+(UIColor*) currentTextColour {
    return nil;
}

@end

@implementation CHMCContactBubbleColourController

-(id) specifiers {
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.title = self.specifier.name;
    activeContactName = self.specifier.name;
    if (_specifiers == nil) {
        [self setStrings];
        _specifiers = [self loadSpecifiersFromPlistName:@"ContactBubble" target:self];

        [[self specifierForID:@"gradient"] setProperty:[NSString stringWithFormat:@"%@ Gradient", self.specifier.name] forKey:@"key"];
        [[self specifierForID:@"SingleBubbleColour"] setProperty:[NSString stringWithFormat:@"%@ BubbleColour", self.specifier.name] forKey:@"key"];
        [[self specifierForID:@"TopBubbleColour"] setProperty:[NSString stringWithFormat:@"%@ TopColour", self.specifier.name] forKey:@"key"];
        [[self specifierForID:@"BottomBubbleColour"] setProperty:[NSString stringWithFormat:@"%@ BottomColour", self.specifier.name] forKey:@"key"];
        [[self specifierForID:@"TextColour"] setProperty:[NSString stringWithFormat:@"%@ TextColour", self.specifier.name] forKey:@"key"];

        [[NSUserDefaults standardUserDefaults] synchronize];

        BOOL gradient = [[self readPreferenceValue:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"gradient"]]] boolValue];

        NSMutableArray* a = [[NSMutableArray alloc] init];
        for (PSSpecifier* s in _specifiers) {
            if (gradient) {
                if (! [s.identifier isEqualToString:@"SingleBubbleColour"]) {
                    [a addObject:s];
                }
            }
            else {
                if (! [s.identifier isEqualToString:@"TopBubbleColour"] && ! [s.identifier isEqualToString:@"BottomBubbleColour"]) {
                    [a addObject:s];
                }
            }
        }
        _specifiers = a;
    }
    return _specifiers;
}

-(void) setStrings {
    plistName = @"ContactBubble";
}

-(void) eraseInfo {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERASE_CONTACT_INFO")
                          message:localisedStringForKey(@"ERASE_CONTACT_INFO_ALERT_MESSAGE")
                          delegate:self
                          cancelButtonTitle:localisedStringForKey(@"NO")
                          otherButtonTitles:localisedStringForKey(@"YES")
                          , nil];
    [alert show];
}

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [NSUserDefaults resetStandardUserDefaults];
        NSString* pathToPlist = @"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.contacts.plist";
        NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:pathToPlist];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@ Gradient", self.specifier.name]];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@ TextColour", self.specifier.name]];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@ BubbleColour", self.specifier.name]];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@ BubbleColourAlpha", self.specifier.name]];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@ TopColour", self.specifier.name]];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@ TopColourAlpha", self.specifier.name]];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@ BottomColour", self.specifier.name]];
        [plist removeObjectForKey:[NSString stringWithFormat:@"%@ BottomColourAlpha", self.specifier.name]];
        [plist writeToFile:pathToPlist atomically:YES];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reloadSpecifiers];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.chewitt.mcproprefs.settingsChanged"), nil, nil, true);
    }
}

+(NSArray*) currentColoursForContact:(NSString*)contactName {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.contacts.plist"];
    NSArray* array;
    BOOL grad = [[dic valueForKey:[NSString stringWithFormat:@"%@ Gradient", contactName]] boolValue];
    if (grad) {
        UIColor* col1 = [UIColor clearColor];
        UIColor* col2 = [UIColor clearColor];
        if ([dic valueForKey:[NSString stringWithFormat:@"%@ TopColour", contactName]]) {
            col1 = UIColorFromHexString([dic valueForKey:[NSString stringWithFormat:@"%@ TopColour", contactName]]);
            if ([dic valueForKey:[NSString stringWithFormat:@"%@ TopColourAlpha", contactName]]) {
                col1 = [col1 colorWithAlphaComponent:[[dic valueForKey:[NSString stringWithFormat:@"%@ TopColourAlpha", contactName]] floatValue]];
            }
        }
        if ([dic valueForKey:[NSString stringWithFormat:@"%@ BottomColour", contactName]]) {
            col2 = UIColorFromHexString([dic valueForKey:[NSString stringWithFormat:@"%@ BottomColour", contactName]]);
            if ([dic valueForKey:[NSString stringWithFormat:@"%@ BottomColourAlpha", contactName]]) {
                col2 = [col2 colorWithAlphaComponent:[[dic valueForKey:[NSString stringWithFormat:@"%@ BottomColourAlpha", contactName]] floatValue]];
            }
        }
        array = [NSArray arrayWithObjects:col1, col2, nil];
    }
    else {
        UIColor* col = [UIColor clearColor];
        if ([dic valueForKey:[NSString stringWithFormat:@"%@ BubbleColour", contactName]]) {
            col = UIColorFromHexString([dic valueForKey:[NSString stringWithFormat:@"%@ BubbleColour", contactName]]);
            if ([dic valueForKey:[NSString stringWithFormat:@"%@ BubbleColourAlpha", contactName]]) {
                col = [col colorWithAlphaComponent:[[dic valueForKey:[NSString stringWithFormat:@"%@ BubbleColourAlpha", contactName]] floatValue]];
            }
        }
        array = [NSArray arrayWithObjects:col, col, nil];
    }
    return array;
}

+(UIColor*) currentTextColourForContact:(NSString*)contactName {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.contacts.plist"];
    if ([dic valueForKey:[NSString stringWithFormat:@"%@ TextColour", contactName]]) {
        return UIColorFromHexString([dic valueForKey:[NSString stringWithFormat:@"%@ TextColour", contactName]]);
    }
    else {
        return [UIColor clearColor];
    }
}

@end

@implementation CHMCSMSBubbleContoller
-(void) setStrings {
    plistName = @"SMSBubble";
}

+(NSArray*) currentColours {
    NSString* gradKey = @"SMSGrad";
    NSString* colKeyName = @"SMSBubble";
    NSString* colKeyNameA = @"SMSBubbleAlpha";
    NSString* topKeyName = @"SMSTopBubble";
    NSString* topKeyNameA = @"SMSTopBubbleAlpha";
    NSString* botKeyName = @"SMSBottomBubble";
    NSString* botKeyNameA = @"SMSBottomBubbleAlpha";

    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath];
    BOOL grad = [[dic valueForKey:gradKey] boolValue];
    UIColor* c1;
    UIColor* c2;
    CGFloat a1;
    CGFloat a2;
    if (grad) {
        c1 = UIColorFromHexString([dic valueForKey:topKeyName]);
        c2 = UIColorFromHexString([dic valueForKey:botKeyName]);
        a1 = ([dic objectForKey:topKeyNameA] == nil) ? 1.0:[[dic valueForKey:topKeyNameA] floatValue];
        a2 = ([dic objectForKey:botKeyNameA] == nil) ? 1.0:[[dic valueForKey:botKeyNameA] floatValue];
    }
    else {
        c1 = c2 = UIColorFromHexString([dic valueForKey:colKeyName]);
        a1 = a2 = ([dic objectForKey:colKeyNameA] == nil) ? 1.0:[[dic valueForKey:colKeyNameA] floatValue];
    }
    return [NSArray arrayWithObjects:[c1 colorWithAlphaComponent:a1], [c2 colorWithAlphaComponent:a2], nil];
}

+(UIColor*) currentTextColour {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath];
    return UIColorFromHexString([dic valueForKey:@"SMSText"]);
}

@end

@implementation CHMCIMBubbleContoller
-(void) setStrings {
    plistName = @"IMBubble";
}

+(NSArray*) currentColours {
    NSString* gradKey = @"IMGrad";
    NSString* colKeyName = @"IMBubble";
    NSString* colKeyNameA = @"IMBubbleAlpha";
    NSString* topKeyName = @"IMTopBubble";
    NSString* topKeyNameA = @"IMTopBubbleAlpha";
    NSString* botKeyName = @"IMBottomBubble";
    NSString* botKeyNameA = @"IMBottomBubbleAlpha";

    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath];
    BOOL grad = [[dic valueForKey:gradKey] boolValue];
    UIColor* c1;
    UIColor* c2;
    CGFloat a1;
    CGFloat a2;
    if (grad) {
        c1 = UIColorFromHexString([dic valueForKey:topKeyName]);
        c2 = UIColorFromHexString([dic valueForKey:botKeyName]);
        a1 = ([dic objectForKey:topKeyNameA] == nil) ? 1.0:[[dic valueForKey:topKeyNameA] floatValue];
        a2 = ([dic objectForKey:botKeyNameA] == nil) ? 1.0:[[dic valueForKey:botKeyNameA] floatValue];
    }
    else {
        c1 = c2 = UIColorFromHexString([dic valueForKey:colKeyName]);
        a1 = a2 = ([dic objectForKey:colKeyNameA] == nil) ? 1.0:[[dic valueForKey:colKeyNameA] floatValue];
    }
    return [NSArray arrayWithObjects:[c1 colorWithAlphaComponent:a1], [c2 colorWithAlphaComponent:a2], nil];
}

+(UIColor*) currentTextColour {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath];
    return UIColorFromHexString([dic valueForKey:@"IMText"]);
}

@end

@implementation CHMCOtherBubbleContoller
-(void) setStrings {
    plistName = @"OtherBubble";
}

+(NSArray*) currentColours {
    NSString* gradKey = @"OtherGrad";
    NSString* colKeyName = @"OtherBubble";
    NSString* colKeyNameA = @"OtherBubbleAlpha";
    NSString* topKeyName = @"OtherTopBubble";
    NSString* topKeyNameA = @"OtherTopBubbleAlpha";
    NSString* botKeyName = @"OtherBottomBubble";
    NSString* botKeyNameA = @"OtherBottomBubbleAlpha";

    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath];
    BOOL grad = [[dic valueForKey:gradKey] boolValue];
    UIColor* c1;
    UIColor* c2;
    CGFloat a1;
    CGFloat a2;
    if (grad) {
        c1 = UIColorFromHexString([dic valueForKey:topKeyName]);
        c2 = UIColorFromHexString([dic valueForKey:botKeyName]);
        a1 = ([dic objectForKey:topKeyNameA] == nil) ? 1.0:[[dic valueForKey:topKeyNameA] floatValue];
        a2 = ([dic objectForKey:botKeyNameA] == nil) ? 1.0:[[dic valueForKey:botKeyNameA] floatValue];
    }
    else {
        c1 = c2 = UIColorFromHexString([dic valueForKey:colKeyName]);
        a1 = a2 = ([dic objectForKey:colKeyNameA] == nil) ? 1.0:[[dic valueForKey:colKeyNameA] floatValue];
    }
    return [NSArray arrayWithObjects:[c1 colorWithAlphaComponent:a1], [c2 colorWithAlphaComponent:a2], nil];
}

+(UIColor*) currentTextColour {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath];
    return UIColorFromHexString([dic valueForKey:@"OtherText"]);
}

@end

@implementation CHMCBackgroundController

-(void) loadImageForPreview {
    NSInteger bgType = [[self readPreferenceValue:[self specifierForID:@"BackgroundType"]] intValue];
    blurRadius = [[self readPreferenceValue:[self specifierForID:@"BGBlurRadius"]] floatValue];

    if (bgType == 2) {
        NSString* wallPath = @"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap";
        if (! [[NSFileManager defaultManager] fileExistsAtPath:wallPath]) {
            wallPath = @"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap";
        }

        unblurredBGImage = [UIImage imageWithContentsOfCPBitmapFile:wallPath flags:nil];
        NSString* cachePath = @"/var/mobile/Library/MCPro/cache/Wall.jpeg";
        [UIImageJPEGRepresentation(unblurredBGImage, 1.0) writeToFile:cachePath atomically:YES];
        if (blurRadius != 0) {
            blurredBGImage = [unblurredBGImage imageWithBlurRadius:blurRadius];
            [UIImageJPEGRepresentation(blurredBGImage, 1.0) writeToFile:@"/var/mobile/Library/MCPro/cache/Wall_blurred.jpeg" atomically:YES];
        }
        else {
            blurredBGImage = unblurredBGImage;
        }
    }
    else {
        NSString* path = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG.jpeg", activeThemeName];
        unblurredBGImage = [UIImage imageWithContentsOfFile:path];
        if (blurRadius != 0) {
            NSString* blurpath = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG_blurred.jpeg", activeThemeName];
            blurredBGImage = [UIImage imageWithContentsOfFile:blurpath];
        }
        else {
            blurredBGImage = unblurredBGImage;
        }
    }
    [UIView transitionWithView:activeCHMCBackgroundImageViewCell.previewImageView
     duration:0.1f
     options:UIViewAnimationOptionTransitionCrossDissolve
     animations:^{
        activeCHMCBackgroundImageViewCell.previewImageView.image = blurredBGImage;
    } completion:NULL];
}

-(void) updateOverlayColour {
    [UIView transitionWithView:activeCHMCBackgroundImageViewCell.previewColourOverlayView
     duration:0.2f
     options:UIViewAnimationOptionTransitionCrossDissolve
     animations:^{
        UIColor* c = [UIColorFromHexString([self readPreferenceValue:[self specifierForID:@"OverlayColour"]]) colorWithAlphaComponent:[[[NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath] valueForKey:@"BackgroundOverlayColourAlpha"]floatValue]];
        activeCHMCBackgroundImageViewCell.previewColourOverlayView.backgroundColor = c;
    } completion:NULL];
}

-(id) specifiers {
    if (_specifiers == nil) {
        ensureThemeForEditIsValid();
        _specifiers = [super loadSpecifiersFromPlistName:@"BackgroundPrefs" target:self];

        for (PSSpecifier* s in _specifiers) {
            [s setProperty:activeThemePathNoPlist forKey:@"defaults"];
        }

        PSSpecifier* typeSpec = [self specifierForID:@"BackgroundType"];
        NSMutableArray* valueArray = [NSMutableArray array];
        NSMutableArray* titleArray = [NSMutableArray array];
        for (NSInteger i = 0; i <= 4; i++) {
            [valueArray addObject:[NSNumber numberWithInt:i]];
            [titleArray addObject:localisedStringForKey([typeSpec.titleDictionary valueForKey:[NSString stringWithFormat:@"%zd", i]])];
        }
        [typeSpec setValues:valueArray titles:titleArray shortTitles:titleArray];

        NSInteger type = [[self readPreferenceValue:[self specifierForID:@"BackgroundType"]] intValue];

        NSMutableArray* a = [[NSMutableArray alloc] init];
        for (PSSpecifier* s in _specifiers) {
            if (type == 0) { // col
                if (! [s.identifier isEqualToString:@"TopColour"] && ! [s.identifier isEqualToString:@"BottomColour"] && ! [s.identifier isEqualToString:@"BackgroundImageButton"] && ! [s.identifier isEqualToString:@"BackgroundImageCell"] && ! [s.identifier isEqualToString:@"BGBlurRadiusGroup"] && ! [s.identifier isEqualToString:@"BGBlurRadius"] && ! [s.identifier isEqualToString:@"OverlayColourGroup"]  && ! [s.identifier isEqualToString:@"OverlayColour"]) {
                    [a addObject:s];
                }
            }
            else if (type == 1) { //grad
                if (! [s.identifier isEqualToString:@"SingleColour"] && ! [s.identifier isEqualToString:@"BackgroundImageButton"] && ! [s.identifier isEqualToString:@"BackgroundImageCell"] && ! [s.identifier isEqualToString:@"BGBlurRadiusGroup"] && ! [s.identifier isEqualToString:@"BGBlurRadius"] && ! [s.identifier isEqualToString:@"OverlayColourGroup"]  && ! [s.identifier isEqualToString:@"OverlayColour"]) {
                    [a addObject:s];
                }
            }
            else if (type == 2) { //wall
                if (! [s.identifier isEqualToString:@"SingleColour"] && ! [s.identifier isEqualToString:@"TopColour"] && ! [s.identifier isEqualToString:@"BottomColour"] && ! [s.identifier isEqualToString:@"BackgroundImageButton"]) {
                    [a addObject:s];
                }
            }
            else if (type == 3) { //image
                if (! [s.identifier isEqualToString:@"SingleColour"] && ! [s.identifier isEqualToString:@"TopColour"] && ! [s.identifier isEqualToString:@"BottomColour"]) {
                    [a addObject:s];
                }
            }
            else if (type == 4) { //contact pic
                if (! [s.identifier isEqualToString:@"SingleColour"] && ! [s.identifier isEqualToString:@"TopColour"] && ! [s.identifier isEqualToString:@"BottomColour"] && ! [s.identifier isEqualToString:@"BackgroundImageButton"] && ! [s.identifier isEqualToString:@"BackgroundImageCell"] && ! [s.identifier isEqualToString:@"BGBlurRadiusGroup"] && ! [s.identifier isEqualToString:@"BGBlurRadius"] && ! [s.identifier isEqualToString:@"OverlayColourGroup"]  && ! [s.identifier isEqualToString:@"OverlayColour"]) {
                    [a addObject:s];
                }
            }
        }
        blurRadius = [[self readPreferenceValue:[self specifierForID:@"BGBlurRadius"]] floatValue];
        _specifiers = a;
    }
    return _specifiers;
}

-(void) setBackgroundType:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    if ([value intValue] == 2 || [value intValue] == 3) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"SETTING_BACKGROUND")
                                  message:nil
                                  delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:nil];
        UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIView * ac = [[UIView alloc] initWithFrame:CGRectMake(0,0,278,spinner.frame.size.height+20)];
        spinner.center = CGPointMake(139.5,spinner.center.y);
        [ac addSubview:spinner];
        [alertView setValue:ac forKey:@"accessoryView"];
        [spinner startAnimating];
        [alertView show];

        if ([value intValue] == 2) {
            NSString* wallPath = @"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap";
            unblurredBGImage = [UIImage imageWithContentsOfCPBitmapFile:wallPath flags:nil];
            NSString* cachePath = @"/var/mobile/Library/MCPro/cache/Wall.jpeg";
            [UIImageJPEGRepresentation(unblurredBGImage, 1.0) writeToFile:cachePath atomically:YES];
            if (blurRadius != 0) {
                blurredBGImage = [unblurredBGImage imageWithBlurRadius:blurRadius];
                [UIImageJPEGRepresentation(blurredBGImage, 1.0) writeToFile:@"/var/mobile/Library/MCPro/cache/Wall_blurred.jpeg" atomically:YES];
            }
            else {
                blurredBGImage = unblurredBGImage;
            }
        }
        else {
            NSString* path = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG.jpeg", activeThemeName];
            unblurredBGImage = [UIImage imageWithContentsOfFile:path];
            if (blurRadius != 0) {
                blurredBGImage = [unblurredBGImage imageWithBlurRadius:blurRadius];
                [UIImageJPEGRepresentation(blurredBGImage, 1.0) writeToFile:[NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG_blurred.jpeg", activeThemeName] atomically:YES];
            }
            else {
                blurredBGImage = unblurredBGImage;
            }
        }
        activeCHMCBackgroundImageViewCell.previewImageView.image = blurredBGImage;
        [alertView dismissWithClickedButtonIndex:0 animated:YES];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reloadSpecifiers];
}

-(void) setBlurRadius:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    blurRadius = [value floatValue];
    blurredBGImage = [unblurredBGImage imageWithBlurRadius:blurRadius];
    [UIView transitionWithView:activeCHMCBackgroundImageViewCell.previewImageView
     duration:0.2f
     options:UIViewAnimationOptionTransitionCrossDissolve
     animations:^{
        activeCHMCBackgroundImageViewCell.previewImageView.image = blurredBGImage;
    } completion:NULL];

    NSInteger bgType = [[self readPreferenceValue:[self specifierForID:@"BackgroundType"]] intValue];

    if (bgType == 2) {
        [UIImageJPEGRepresentation(blurredBGImage, 1.0) writeToFile:@"/var/mobile/Library/MCPro/cache/Wall_blurred.jpeg" atomically:YES];
    }
    else {
        [UIImageJPEGRepresentation(blurredBGImage, 1.0) writeToFile:[NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG_blurred.jpeg", activeThemeName] atomically:YES];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reloadSpecifier:specifier];
}

-(void) chooseBackgroundImage {
    CHUIImagePickerController* mediaUI = [[CHUIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    [self presentViewController:mediaUI animated:YES completion:nil];
}

-(void) imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    UIImage* newImage;
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        newImage = (UIImage*)[info objectForKey:UIImagePickerControllerOriginalImage];
        if (newImage.imageOrientation != UIImageOrientationUp) {
            UIGraphicsBeginImageContextWithOptions(newImage.size, NO, newImage.scale);
            [newImage drawInRect:(CGRect) {CGPointZero, newImage.size }];
            newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    UIImage* newBlurredImage;
    if (blurRadius != 0) {
        newBlurredImage = [newImage imageWithBlurRadius:blurRadius];
        [UIImageJPEGRepresentation(newBlurredImage, 1.0) writeToFile:[NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG_blurred.jpeg", activeThemeName] atomically:YES];
    }
    else {
        newBlurredImage = newImage;
    }
    activeCHMCBackgroundImageViewCell.previewImageView.image = newBlurredImage;
    NSString* path = [NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG.jpeg", activeThemeName];
    [UIImageJPEGRepresentation(newImage, 1.0) writeToFile:path atomically:YES];
    unblurredBGImage = newImage;
    blurredBGImage = newBlurredImage;
}

+(NSArray*) currentColours {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath];
    NSArray* array;
    NSInteger type = [[dic valueForKey:@"BackgroundType"] intValue];
    if (type == 1) {
        array = [NSArray arrayWithObjects:UIColorFromHexString([dic valueForKey:@"BackgroundTopColour"]), UIColorFromHexString([dic valueForKey:@"BackgroundBottomColour"]), nil];
    }
    else if (type == 0) {
        array = [NSArray arrayWithObjects:UIColorFromHexString([dic valueForKey:@"BackgroundColour"]), UIColorFromHexString([dic valueForKey:@"BackgroundColour"]), nil];
    }
    else {
        array = [NSArray arrayWithObjects:[UIColor clearColor], nil];
    }
    return array;
}

+(UIColor*) currentTextColour {
    return [UIColor clearColor];
}

+(BOOL) isColours {
    NSInteger type = [[[NSMutableDictionary dictionaryWithContentsOfFile:activeThemePath] valueForKey:@"BackgroundType"] intValue];
    return type == 0 || type == 1;
}

-(void) viewWillAppear:(BOOL)anim {
    [super viewWillAppear:anim];
    [self reloadSpecifiers];
}

@end

@implementation CHMCColourPickerController

-(id) specifiers {
    if (_specifiers == nil) {
        colourKeyName = self.specifier.properties[@"key"];
        alphaKeyName = [NSString stringWithFormat:@"%@%@", self.specifier.properties[@"key"], @"Alpha"];
        self.title =  localisedStringForKey(self.specifier.properties[@"label"]);

        if (self.specifier.properties[@"defaults"] == nil) {
            plistPath = activeThemePath;
        }
        else if ([self.specifier.properties[@"defaults"] hasPrefix:@"/"]) {
            plistPath = [NSString stringWithFormat:@"%@.plist", self.specifier.properties[@"defaults"]];
        }
        else {
            plistPath = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", self.specifier.properties[@"defaults"]];
        }

        if (! [colourKeyName isEqualToString:@"AppTint"] && [colourKeyName componentsSeparatedByString:@" "].count < 1) {
            ensureThemeForEditIsValid();
        }
        if (! colorPickerView) {
            [self performSelector:@selector(createPickerView) withObject:nil afterDelay:0.01];
        }
        PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:@" " target:self set:nil get:nil detail:nil cell:[PSTableCell cellTypeFromString:@"PSGroupCell"] edit:0];
        _specifiers = [NSArray arrayWithObjects:spec, nil];
    }
    return _specifiers;
}

-(void) action:(HRColorPickerView*)obj {
    [self setPreferenceValue:HexStringFromUIColor(obj.color) specifier:self.specifier];
    PSSpecifier* alphaSpec = [PSSpecifier preferenceSpecifierNamed:@"Alpha"
                              target:self
                              set:nil
                              get:nil
                              detail:nil
                              cell:[PSTableCell cellTypeFromString:@"PSLinkListCell"]
                              edit:0];
    [alphaSpec setProperty:alphaKeyName forKey:@"key"];
    [alphaSpec setProperty:plistPath forKey:@"defaults"];
    [alphaSpec setProperty:[NSNumber numberWithFloat:1.0] forKey:@"default"];
    [self setPreferenceValue:[NSNumber numberWithFloat:obj.alphaValue] specifier:alphaSpec];
    [(PSListController*)_parentController reloadSpecifier:self.specifier];
}

-(void) createPickerView {
    colorPickerView = [[HRColorPickerView alloc] init];
    CGRect frame = ((UIView*)self.view).frame;
    frame = CGRectMake(0, 0, frame.size.width, frame.size.height-66);
    if (is_IOS_8) {
        frame.origin.y = 66;
    }
    if (iPad) {
        frame = CGRectMake(frame.size.width/2-200, 75, 400, 600);
    }
    colorPickerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    colorPickerView.frame = frame;
    colorPickerView.backgroundColor = [UIColor clearColor];
    colorPickerView.wantsAlpha = [self.specifier.properties[@"alpha"] boolValue];

    if (! plistPath) {
        plistPath = activeThemePath;
    }

    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    UIColor* col = [UIColor clearColor];
    CGFloat alpha = 1.0;

    if ([dic valueForKey:alphaKeyName]) {
        alpha = [[dic valueForKey:alphaKeyName] floatValue];
    }
    colorPickerView.alphaValue = alpha;

    if ([dic valueForKey:colourKeyName]) {
        col = UIColorFromHexString([dic valueForKey:colourKeyName]);
    }
    colorPickerView.color = col;

    [colorPickerView addTarget:self
     action:@selector(action:)
     forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:colorPickerView];
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    id val = nil;
    if (! dic[specifier.properties[@"key"]]) {
        val = specifier.properties[@"default"];
    }
    else {
        val = dic[specifier.properties[@"key"]];
    }

    if ([specifier.properties[@"negate"] boolValue]) {
        val = [NSNumber numberWithInt:(NSInteger) ! [val boolValue]];
    }
    return val;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefsPath]];
    if ([specifier.properties[@"negate"] boolValue]) {
        [defaults setObject:[NSNumber numberWithInt:(NSInteger) ! [value boolValue]] forKey:specifier.properties[@"key"]];
    }
    else {
        [defaults setObject:value forKey:specifier.properties[@"key"]];
    }
    [defaults writeToFile:prefsPath atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

@end

@implementation CHMCChatViewController
-(id) specifiers {
    if (_specifiers == nil) {
        ensureThemeForEditIsValid();
        _specifiers = [self loadSpecifiersFromPlistName:@"ChatViewPrefs" target:self];
        for (PSSpecifier* s in _specifiers) {
            [s setProperty:activeThemePathNoPlist forKey:@"defaults"];
        }

        PSSpecifier* typeSpec = [self specifierForID:@"BubbleTails"];
        NSMutableArray* valueArray = [NSMutableArray array];
        NSMutableArray* titleArray = [NSMutableArray array];
        for (NSInteger i = 1; i < 4; i++) {
            [valueArray addObject:[NSNumber numberWithInt:i]];
            [titleArray addObject:localisedStringForKey([typeSpec.titleDictionary valueForKey:[NSString stringWithFormat:@"%zd", i]])];
        }
        [typeSpec setValues:valueArray titles:titleArray shortTitles:titleArray];
    }
    return _specifiers;
}

@end

@implementation CHMCConvoListController

-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"ConvoListPrefs" target:self];
        BOOL pics = [[self readPreferenceValue:[self specifierForID:@"ListContactPics"]] boolValue];
        if (! pics) {
            NSMutableArray* a = [[NSMutableArray alloc] init];
            for (NSInteger i = 0; i < _specifiers.count; i++) {
                if (i != 2 && i != 3) {
                    [a addObject:[_specifiers objectAtIndex:i]];
                }
            }
            _specifiers = [NSArray arrayWithArray:a];
        }
    }
    return _specifiers;
}

-(void) setContactPicDiameter:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    system_nd("killall MobileSMS");
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reloadSpecifier:specifier];
}

-(void) setContactPicsEnabled:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    BOOL enabled = [value boolValue];
    if (enabled) {
        id prefs = [self loadSpecifiersFromPlistName:@"ConvoListPrefs" target:self];
        [self insertSpecifier:[prefs objectAtIndex:2] afterSpecifier:[_specifiers objectAtIndex:1] animated:YES];
        [self insertSpecifier:[prefs objectAtIndex:3] afterSpecifier:[_specifiers objectAtIndex:2] animated:YES];
    }
    else {
        [self removeSpecifier:[_specifiers objectAtIndex:2] animated:YES];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

@end

@implementation CHMCChatViewPermaController

-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"ChatViewPermaPrefs" target:self];
    }
    return _specifiers;
}

@end

@implementation CHMCOtherPrefsController

static NSInteger base = 10;

-(void) viewWillAppear:(BOOL)a {
    [super viewWillAppear:a];
    [self reloadSpecifier:[self specifierForID:@"AppTint"]];
    if ([self specifierForID:@"DarkModeTimeCell"]) {
        [self reloadSpecifier:[self specifierForID:@"DarkModeTimeCell"]];
    }
    if ([self specifierForID:@"DMCustomBGColour"]) {
        [self reloadSpecifier:[self specifierForID:@"DMCustomBGColour"]];
        [self reloadSpecifier:[self specifierForID:@"DMCustomPColour"]];
        [self reloadSpecifier:[self specifierForID:@"DMCustomSColour"]];
    }
}

-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"OtherPrefs" target:self];
        BOOL darkModeScheduled = [[self readPreferenceValue:[self specifierForID:@"DarkModeScheduled"]] boolValue];
        BOOL bigBubblesEnabled = [[self readPreferenceValue:[self specifierForID:@"BigBubbles"]] boolValue];
        NSInteger darkModeType = [[self readPreferenceValue:[self specifierForID:@"DarkModeSegmentedCell"]] intValue];
        NSMutableArray* a = [NSMutableArray array];
        for (PSSpecifier* s in _specifiers) {
            BOOL toAdd = YES;
            if (iPad && ([s.identifier isEqualToString:@"QuickSwitcher"] || [s.identifier isEqualToString:@"QuickSwitcherGroup"] || [s.identifier isEqualToString:@"PlaceholderGroup"] || [s.identifier isEqualToString:@"NameInPlaceholder"] || [s.identifier isEqualToString:@"BigBubblesGroup"] || [s.identifier isEqualToString:@"BigBubbles"] || [s.identifier isEqualToString:@"BigBubbleWidth"])) {
                toAdd = NO;
            }

            if (darkModeScheduled && [s.identifier isEqualToString:@"DarkModeSegmentedCell"]) {
                toAdd = NO;
            }

            if (! darkModeScheduled && ([s.identifier isEqualToString:@"DarkModeTimeCell"] || [s.identifier isEqualToString:@"DarkModeTheme"])) {
                toAdd = NO;
            }

            if ((darkModeType != 2 || darkModeScheduled) && ([s.identifier isEqualToString:@"DMCustomBGColour"] || [s.identifier isEqualToString:@"DMCustomPColour"] || [s.identifier isEqualToString:@"DMCustomSColour"])) {
                toAdd = NO;
            }

            if (! bigBubblesEnabled && [s.identifier isEqualToString:@"BigBubbleWidth"]) {
                toAdd = NO;
            }

            if (toAdd) {
                [a addObject:s];
            }
        }

        PSSpecifier* segmented = [self specifierForID:@"DarkModeSegmentedCell"];
        if (segmented) {
            NSMutableArray* valueArray = [NSMutableArray array];
            NSMutableArray* titleArray = [NSMutableArray array];
            for (NSInteger i = 0; i < 3; i++) {
                [valueArray addObject:[NSNumber numberWithInt:i]];
                [titleArray addObject:localisedStringForKey([segmented.titleDictionary valueForKey:[NSString stringWithFormat:@"%zd", i]])];
            }
            [segmented setValues:valueArray titles:titleArray shortTitles:titleArray];
        }

        PSSpecifier* darkTheme = [self specifierForID:@"DarkModeTheme"];
        if (darkTheme) {
            updateDirectoryList();
            NSMutableArray* valueArray = directoryList;
            [valueArray insertObject:@"" atIndex:0];
            NSMutableArray* titleArray = directoryTitlesList;
            [titleArray insertObject:localisedStringForKey(@"SAME_AS_PRIMARY") atIndex:0];
            [darkTheme setValues:valueArray titles:titleArray shortTitles:titleArray];
        }

        _specifiers = [NSArray arrayWithArray:a];
    }
    return _specifiers;
}

-(void) setBigBubblesEnabled:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    if ([value boolValue]) {
        [self insertSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:13] afterSpecifier:[self specifierForID:@"BigBubbles"] animated:YES];
    }
    else {
        [self removeSpecifier:[self specifierForID:@"BigBubbleWidth"] animated:YES];
    }
    system_nd("find ~/Library/SMS/Attachments/ -name *preview* -delete");
    system_nd("killall MobileSMS");
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

-(void) setDarkModeScheduled:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    if ([value boolValue]) {
        [self removeSpecifier:[self specifierForID:@"DarkModeSegmentedCell"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"DMCustomBGColour"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"DMCustomPColour"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"DMCustomSColour"] animated:YES];
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+3] animated:YES];
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+4] animated:YES];
    }
    else {
        [self removeSpecifier:[self specifierForID:@"DarkModeTimeCell"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"DarkModeTheme"] animated:YES];
        PSSpecifier* segmented = [[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+2];
        NSMutableArray* valueArray = [NSMutableArray array];
        NSMutableArray* titleArray = [NSMutableArray array];
        for (NSInteger i = 0; i < 3; i++) {
            [valueArray addObject:[NSNumber numberWithInt:i]];
            [titleArray addObject:localisedStringForKey([segmented.titleDictionary valueForKey:[NSString stringWithFormat:@"%zd", i]])];
        }
        [segmented setValues:valueArray titles:titleArray shortTitles:titleArray];
        [self addSpecifier:segmented animated:YES];
        if ([[self readPreferenceValue:[self specifierForID:@"DarkModeSegmentedCell"]] intValue] == 2) {
            [self addSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+5] animated:YES];
            [self addSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+6] animated:YES];
            [self addSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+7] animated:YES];
        }
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

-(void) setDarkModeType:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    NSInteger val = [value intValue];
    if (val == 2) {
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+5] animated:YES];
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+6] animated:YES];
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] objectAtIndex:base+7] animated:YES];
    }
    else {
        [self removeSpecifier:[self specifierForID:@"DMCustomBGColour"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"DMCustomPColour"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"DMCustomSColour"] animated:YES];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

-(void) setBigBubbleWidth:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    system_nd("find ~/Library/SMS/Attachments/ -name *preview* -delete");
    system_nd("killall MobileSMS");
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reloadSpecifier:specifier];
}

@end

@implementation CHMCInfoController

-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"InfoList" target:self];
    }
    return _specifiers;
}

@end

@implementation CHMCCompatPrefsController

-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"CompatPrefs" target:self];
    }
    return _specifiers;
}

@end

@implementation CHMCBetaController

-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"BetaInfo" target:self];
    }
    return _specifiers;
}

@end

@implementation CHMCTimeRangeEntryController

-(id) specifiers {
    if (_specifiers == nil) {
        isSettingTo = NO;
        if (! datePicker) {
            [self performSelector:@selector(createViews) withObject:nil afterDelay:0.01];
        }

        self.title = localisedStringForKey(@"DM_SCHEDULE_TITLE");

        PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:@" "
                             target:self
                             set:nil
                             get:nil
                             detail:nil
                             cell:[PSTableCell cellTypeFromString:@"PSStaticTextCell"]
                             edit:0];
        [spec setProperty:[CHMCBlankTableCell class] forKey:@"cellClass"];
        [spec setProperty:[NSNumber numberWithInt:20] forKey:@"height"];

        PSSpecifier* group = [PSSpecifier preferenceSpecifierNamed:@" "
                              target:self
                              set:nil
                              get:nil
                              detail:nil
                              cell:[PSTableCell cellTypeFromString:@"PSGroupCell"]
                              edit:0];

        PSSpecifier* fromSpec = [PSSpecifier preferenceSpecifierNamed:localisedStringForKey(@"FROM")
                                 target:self
                                 set:nil
                                 get:nil
                                 detail:nil
                                 cell:[PSTableCell cellTypeFromString:@"PSButtonCell"]
                                 edit:0];
        [fromSpec setButtonAction:@selector(switchToFrom)];
        [fromSpec setProperty:[CHMCDatePickerViewCell class] forKey:@"cellClass"];

        PSSpecifier* toSpec = [PSSpecifier preferenceSpecifierNamed:localisedStringForKey(@"TO")
                               target:self
                               set:nil
                               get:nil
                               detail:nil
                               cell:[PSTableCell cellTypeFromString:@"PSButtonCell"]
                               edit:0];
        [toSpec setButtonAction:@selector(switchToTo)];
        [toSpec setProperty:[CHMCDatePickerViewCell class] forKey:@"cellClass"];

        _specifiers = [NSArray arrayWithObjects:spec, group, fromSpec, toSpec, nil];
    }
    return _specifiers;
}

-(void) switchToFrom {
    isSettingTo = NO;
    activeToCell.selected = NO;
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist"];
    NSString* timeString = [plist valueForKey:@"DarkModeScheduleFromTime"];
    if (! timeString) {
        timeString = @"22:00";
    }
    NSArray* parts = [timeString componentsSeparatedByString:@":"];
    comps.hour = [[parts objectAtIndex:0] integerValue];
    comps.minute = [[parts objectAtIndex:1] integerValue];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDate* periodDate = [calendar dateFromComponents:comps];
    [datePicker setDate:periodDate animated:YES];
}

-(void) switchToTo {
    isSettingTo = YES;
    activeFromCell.selected = NO;
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist"];
    NSString* timeString = [plist valueForKey:@"DarkModeScheduleToTime"];
    if (! timeString) {
        timeString = @"08:00";
    }
    NSArray* parts = [timeString componentsSeparatedByString:@":"];
    comps.hour = [[parts objectAtIndex:0] integerValue];
    comps.minute = [[parts objectAtIndex:1] integerValue];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDate* periodDate = [calendar dateFromComponents:comps];
    [datePicker setDate:periodDate animated:YES];
}

-(void) createViews {
    self.table.scrollEnabled = NO;
    NSInteger screenHeight = currentScreenBoundsDependOnOrientation().size.height;
    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, screenHeight-216-64, self.table.frame.size.width, 216)];
    datePicker.datePickerMode = UIDatePickerModeTime;
    datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [datePicker addTarget:self action:@selector(pickerChanged:) forControlEvents:UIControlEventValueChanged];
    [self.table addSubview:datePicker];

    NSDateComponents* comps = [[NSDateComponents alloc] init];
    NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist"];
    NSString* timeString = [plist valueForKey:@"DarkModeScheduleFromTime"];
    activeFromCell.titleTextLabel.text = [NSString stringWithFormat:@"%@ %@", localisedStringForKey(@"FROM"), timeString];
    NSString* timeStringTo = [plist valueForKey:@"DarkModeScheduleToTime"];
    activeToCell.titleTextLabel.text = [NSString stringWithFormat:@"%@ %@", localisedStringForKey(@"TO"), timeStringTo];
    if (! timeString) {
        timeString = @"00:00";
    }
    NSArray* parts = [timeString componentsSeparatedByString:@":"];
    comps.hour = [[parts objectAtIndex:0] integerValue];
    comps.minute = [[parts objectAtIndex:1] integerValue];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDate* periodDate = [calendar dateFromComponents:comps];
    [datePicker setDate:periodDate animated:NO];

    activeFromCell.selected = YES;
}

-(void) pickerChanged:(id)sender {
    UIDatePicker* picker = (UIDatePicker*)sender;
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString* time = [formatter stringFromDate:[picker date]];
    NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist"];
    NSString* key;
    if (isSettingTo) {
        key = @"DarkModeScheduleToTime";
        activeToCell.titleTextLabel.text = [NSString stringWithFormat:@"%@ %@", localisedStringForKey(@"TO"), time];
    }
    else {
        key = @"DarkModeScheduleFromTime";
        activeFromCell.titleTextLabel.text = [NSString stringWithFormat:@"%@ %@", localisedStringForKey(@"FROM"), time];
    }
    [plist setValue:time forKey:key];
    [plist writeToFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist" atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.chewitt.mcproprefs.settingsChanged"), nil, nil, true);
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CHMCLinkToColourPickerCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        circle = [[CircleColourView alloc] initWithFrame:CGRectMake(self.frame.size.width-30, 7, 30, 30) andColour:[UIColor clearColor]];
        [self.contentView addSubview:circle];
        [self valueLabel].hidden = YES;
    }
    return self;
}

-(void) setValue:(id)value {
    [super setValue:value];

    NSString* plistPath;
    if (self.specifier.properties[@"defaults"] == nil) {
        plistPath = activeThemePath;
    }
    else if ([self.specifier.properties[@"defaults"] hasPrefix:@"/"]) {
        plistPath = [NSString stringWithFormat:@"%@.plist", self.specifier.properties[@"defaults"]];
    }
    else {
        plistPath = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", self.specifier.properties[@"defaults"]];
    }

    UIColor* col = UIColorFromHexString(value);
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    NSString* alphaKey = [NSString stringWithFormat:@"%@Alpha", self.specifier.properties[@"key"]];
    CGFloat alpha = ([dic objectForKey:alphaKey] == nil) ? 1.0:[[dic valueForKey:alphaKey] floatValue];
    circle.backgroundColor = [col colorWithAlphaComponent:alpha];
}

@end

@implementation CHMCBubbleLinkCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        CircleGradientView* v = [[CircleGradientView alloc] initWithFrame:CGRectMake(self.frame.size.width-30, 7, 30, 30) andColours:[arg3.detailControllerClass currentColours] andTextColour:[arg3.detailControllerClass currentTextColour]];
        [self.contentView addSubview:v];
    }
    return self;
}

@end

@implementation CHMCBackgroundLinkCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        if ([arg3.detailControllerClass respondsToSelector:@selector(isColours)]) {
            if ([arg3.detailControllerClass isColours]) {
                CircleGradientView* v = [[CircleGradientView alloc] initWithFrame:CGRectMake(self.frame.size.width-30, 7, 30, 30) andColours:[arg3.detailControllerClass currentColours] andTextColour:[arg3.detailControllerClass currentTextColour]];
                [self.contentView addSubview:v];
            }
        }
    }
    return self;
}

@end

@implementation CHMCThemeListItemCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        if ([arg3.name isEqualToString:localisedStringForKey(@"DEFAULT")]) {
            defaultCell = self;
        }
        if (([arg3.name isEqualToString:localisedStringForKey(@"DEFAULT")] || [defaultThemeNames containsObject:arg3.name])) {
            if (is_IOS_8) {
                [nonEditableCells addObject:self];
            }
            else {
                ((UIScrollView*)self.contentView.superview).scrollEnabled = NO;
            }
        }
        if ([[arg3.name stringByReplacingOccurrencesOfString:@" " withString:@"_"] isEqualToString:[activeThemeSelectionController readPreferenceValue:activeThemeSelectionController.specifier]]) {
            [self setChecked:YES];
        }
    }
    return self;
}

-(void) setSelected:(BOOL)arg1 animated:(BOOL)arg2 {
    [super setSelected:arg1 animated:arg2];
    if (arg1) {
        [self setChecked:arg1];
        [activeThemeSelectionController setPreferenceValue:[self.specifier.name stringByReplacingOccurrencesOfString:@" " withString:@"_"] specifier:activeThemeSelectionController.specifier];
        for (PSSpecifier* s in activeThemeSelectionController.specifiers) {
            CHMCThemeListItemCell* cell = [activeThemeSelectionController cachedCellForSpecifier:s];
            if (! [cell isEqual:self]) {
                [cell setChecked:NO];
            }
        }
    }
}

-(void) setEditing:(BOOL)editing animated:(BOOL)animated {
    if (! [self.specifier.name isEqualToString:localisedStringForKey(@"DEFAULT")] && ! [defaultThemeNames containsObject:self.specifier.name]) {
        [super setEditing:editing animated:animated];
    }
}

@end

@implementation PSDeleteTableCell
-(void) setValueChangedTarget:(id)target action:(SEL)action userInfo:(NSDictionary*)info {
    [self setTarget:target];
    [self setAction:action];
}

-(UILabel*) titleTextLabel {
    UILabel* res = [super titleTextLabel];
    res.textColor = [UIColor whiteColor];
    return res;
}

@end

@implementation CHMCBannerCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 100);

        NSString* bundleName = @"MCProPrefs";

        UIView* containerView = [[UIView alloc] initWithFrame:self.frame];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        containerView.clipsToBounds = YES;

        UIImageView* titleImage = [[UIImageView alloc] initWithFrame:self.frame];
        if (iPad) {
            titleImage.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle/banner_ipad.png", bundleName]];
            containerView.layer.cornerRadius = 5;
        }
        else {
            titleImage.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle/banner_iphone.png", bundleName]];
        }

        titleImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleImage.contentMode = UIViewContentModeScaleAspectFill;

        [containerView addSubview:titleImage];
        [self.contentView addSubview:containerView];
    }
    return self;
}

@end

@implementation CHMCBackgroundImageViewCell:PSTableCell

-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        activeCHMCBackgroundImageViewCell = self;
        CGFloat height = 0.625* [UIScreen mainScreen].bounds.size.height;
        CGFloat cellHeight = height + 30;
        [arg3 setProperty:[NSNumber numberWithFloat:cellHeight] forKey:@"height"];
        CGFloat width = 0.625* [UIScreen mainScreen].bounds.size.width;
        if (iPad) {
            width = 355;
            height = 266.25;
        }

        CGRect previewFrame = CGRectMake((self.frame.size.width/2) - (width/2), (cellHeight - height)/2, width, height);
        _previewImageView = [[UIImageView alloc] initWithFrame:previewFrame];
        _previewImageView.backgroundColor = [UIColor blackColor];
        _previewImageView.layer.cornerRadius = 5;
        _previewImageView.layer.masksToBounds = YES;
        _previewImageView.contentMode = UIViewContentModeScaleAspectFill;
        _previewImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.contentView addSubview:_previewImageView];

        _previewColourOverlayView = [[UIView alloc] initWithFrame:previewFrame];
        _previewColourOverlayView.layer.cornerRadius = 5;
        _previewColourOverlayView.layer.masksToBounds = YES;
        _previewColourOverlayView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.contentView addSubview:_previewColourOverlayView];
    }
    [self performSelector:@selector(loadImageForPreview) withObject:nil afterDelay:0.05];
    return self;
}

-(void) loadImageForPreview {
    UITableView* table = [self _tableView];
    CHMCBackgroundController* currentController = (CHMCBackgroundController*)table.delegate;
    [currentController loadImageForPreview];
    [currentController updateOverlayColour];
}

@end

@implementation CHMCContactLinkCell

-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)arg3 {
    return [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
}

@end

@implementation CHMCContactLinkCellWithColours

-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        CircleGradientView* v = [[CircleGradientView alloc] initWithFrame:CGRectMake(self.frame.size.width-30, 7, 30, 30) andColours:[arg3.detailControllerClass currentColoursForContact:arg3.name] andTextColour:[arg3.detailControllerClass currentTextColourForContact:arg3.name]];
        [self.contentView addSubview:v];
    }
    return self;
}

@end

@implementation CHMCBetterSliderCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        CGRect frame = [self frame];
        UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(frame.size.width-50, 0, 50, frame.size.height);
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [button setTitle:@"" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(presentPopup) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];

        self.control.tintColor = TINT_COLOUR;
    }
    return self;
}

-(void) presentPopup {
    title = self.specifier.name;
    maximumValue = [[self.specifier propertyForKey:@"max"] floatValue];
    minimumValue = [[self.specifier propertyForKey:@"min"] floatValue];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                          message:[NSString stringWithFormat:@"%@ %zd %@ %zd.", localisedStringForKey(@"SLIDER_ENTRY_TEXT"), (NSInteger)minimumValue, localisedStringForKey(@"AND"), (NSInteger)maximumValue]
                          delegate:self
                          cancelButtonTitle:localisedStringForKey(@"CANCEL")
                          otherButtonTitles:localisedStringForKey(@"ENTER")
                          , nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 12345;
    [alert show];
    [[alert textFieldAtIndex:0] setDelegate:self];
    [[alert textFieldAtIndex:0] resignFirstResponder];
    [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [[alert textFieldAtIndex:0] becomeFirstResponder];
}

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 12345) {
        if (buttonIndex == 1) {
            CGFloat value = [[alertView textFieldAtIndex:0].text floatValue];
            if (value <= maximumValue && value >= minimumValue) {
                [self setValue:[NSNumber numberWithInt:value]];
                [PSRootController setPreferenceValue:[NSNumber numberWithInt:value] specifier:self.specifier];
                [[NSUserDefaults standardUserDefaults] synchronize];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[self.specifier propertyForKey:@"PostNotification"], NULL, NULL, YES);
                });
                if ([self.specifier.identifier isEqualToString:@"CPicRadiusList"]) {
                    system_nd("killall MobileSMS");
                }
                else if ([self.specifier.identifier isEqualToString:@"BigBubbles"]) {
                    system_nd("find ~/Library/SMS/Attachments/ -name *preview* -delete");
                    system_nd("killall MobileSMS");
                }
            }
            else {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localisedStringForKey(@"ERROR")
                                      message:localisedStringForKey(@"SLIDER_ERROR_TEXT")
                                      delegate:self
                                      cancelButtonTitle:localisedStringForKey(@"OK")
                                      otherButtonTitles:nil
                                      , nil];
                alert.tag = 85230234;
                [alert show];
            }
        }
        [[alertView textFieldAtIndex:0] resignFirstResponder];
    }
    else if (alertView.tag == 85230234) {
        [self presentPopup];
    }
}

@end

@implementation CHMCTimeRangeControlCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        UILabel* fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 10, 50, 19)];
        fromLabel.font = [UIFont systemFontOfSize:16];
        fromLabel.text = localisedStringForKey(@"FROM");
        [self.contentView addSubview:fromLabel];

        UILabel* toLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 34.5, 50, 19)];
        toLabel.font = [UIFont systemFontOfSize:16];
        toLabel.text = localisedStringForKey(@"TO");
        [self.contentView addSubview:toLabel];

        NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist"];

        UILabel* fromTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 50, 10, 50, 19)];
        fromTimeLabel.font = [UIFont systemFontOfSize:16];
        fromTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        fromTimeLabel.text = [plist valueForKey:@"DarkModeScheduleFromTime"];
        fromTimeLabel.textColor = TINT_COLOUR;
        fromTimeLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:fromTimeLabel];

        UILabel* toTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 50, 34.5, 50, 19)];
        toTimeLabel.font = [UIFont systemFontOfSize:16];
        toTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        toTimeLabel.text = [plist valueForKey:@"DarkModeScheduleToTime"];
        toTimeLabel.textColor = TINT_COLOUR;
        toTimeLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:toTimeLabel];
    }
    return self;
}

@end

@implementation CHMCDatePickerViewCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        if ([arg3.name isEqualToString:localisedStringForKey(@"FROM")]) {
            activeFromCell = self;
            self.selected = YES;
        }
        else {
            activeToCell = self;
        }

        self.titleTextLabel.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];
    self.titleTextLabel.frame = CGRectMake(self.frame.size.width/2 - 50, 12, 100, 20);
    self.titleTextLabel.textColor = TINT_COLOUR;

    NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.mcproprefs.perma.plist"];
    if ([self.specifier.name isEqualToString:localisedStringForKey(@"FROM")]) {
        self.titleTextLabel.text = [NSString stringWithFormat:@"%@ %@", localisedStringForKey(@"FROM"), [plist valueForKey:@"DarkModeScheduleFromTime"]];
    }
    else {
        self.titleTextLabel.text = [NSString stringWithFormat:@"%@ %@", localisedStringForKey(@"TO"), [plist valueForKey:@"DarkModeScheduleToTime"]];
    }
}

-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    if (! selected) {
        if (([self isEqual:activeFromCell] && ! isSettingTo) || ([self isEqual:activeToCell] && isSettingTo)) {}
        else {
            [super setSelected:selected animated:animated];
        }
    }
    else {
        [super setSelected:selected animated:animated];
    }
}

@end

@implementation CHMCBlankTableCell

-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        self.hidden = YES;
    }
    return self;
}

@end

@implementation CHMCButtonCell
-(void) layoutSubviews {
    [super layoutSubviews];
    self.titleTextLabel.textColor = TINT_COLOUR;
}

@end

#import "Headers.h"
#import "UIImage+ImageEffects.h"
#import <CommonCrypto/CommonCrypto.h>
#import <MobileGestalt/MobileGestalt.h>
#import <AddressBook/AddressBook.h>
#import "CHQuickSwitcher.h"

#define themesBaseDirectory @"var/mobile/Library/MCPro/Themes"
#define prefsBaseDirectory @"var/mobile/Library/Preferences/me.chewitt.mcproprefs"
#define contactsPrefsName @"contacts"
#define convosPrefsName @"convos"
#define permaPrefsName @"perma"

static NSDictionary* activeThemeInfo;
static NSDictionary* fallbackThemeInfo;
static NSDictionary* defaultThemeInfo;
static NSDictionary* permaPrefs;
static NSDictionary* contactSpecificColours;
static NSDictionary* convoSpecificThemes;
static NSString* fallbackThemeName;
static NSString* darkModeThemeName;
static BOOL activeConvoIsGroup;
static NSString* activeConvoName;
static BOOL isDarkModeActive;
static BOOL isDarkModeActiveForCouria;
static BOOL isValidApplicationForDarkMode;
static UIColor* darkModeBackgroundColour;
static UIColor* darkModeForegroundColour;
static UIColor* darkModeBrightForegroundColour;

//static BOOL activeMessageServiceID;
static IMService* activeMessageService;
static CKConversation* activeConversation;
static NSString* activeConversationID;

static NSString *stringForPermaKey(NSString* key) {
    NSString* value;
    value = [permaPrefs valueForKey:key];
    return value;
}

static UIColor *UIColorFromHexString(NSString* hexString) {
    if (! hexString || ! [hexString isKindOfClass:[NSString class]]) {
        return nil;
    }
    unsigned rgbValue = 0;
    NSScanner* scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];  // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

static UIColor *colourForActiveKey(NSString* key) {
    NSString* hexStringForColour;

    if ([activeThemeInfo valueForKey:key]) {
        hexStringForColour = [activeThemeInfo valueForKey:key];
    }
    else {
        hexStringForColour = [defaultThemeInfo valueForKey:key];
    }

    return UIColorFromHexString(hexStringForColour);
}

static UIColor *colourForPermaKey(NSString* key) {
    NSString* hexStringForColour = [permaPrefs valueForKey:key];
    if (! hexStringForColour) {
        hexStringForColour = @"FF007A";
    }
    return UIColorFromHexString(hexStringForColour);
}

static BOOL boolForActiveKey(NSString* key) {
    BOOL value;
    //if([activeThemeInfo valueForKey:key])
    value = [[activeThemeInfo valueForKey:key] boolValue];
    //else
    //	value = [[defaultThemeInfo valueForKey:key] boolValue];
    //NSLog(@"BOOL: %i forKey: %@",value,key);
    return value;
}

static BOOL boolForPermaKey(NSString* key) {
    BOOL value;
    value = [[permaPrefs valueForKey:key] boolValue];
    return value;
}

static NSInteger intForActiveKey(NSString* key) {
    NSInteger value;
    if ([activeThemeInfo valueForKey:key]) {
        value = [[activeThemeInfo valueForKey:key] intValue];
    }
    else {
        value = [[defaultThemeInfo valueForKey:key] intValue];
    }
    return value;
}

static NSInteger intForPermaKey(NSString* key) {
    NSInteger value;
    value = [[permaPrefs valueForKey:key] intValue];
    return value;
}

static CGFloat floatForActiveKey(NSString* key) {
    CGFloat value;
    if ([activeThemeInfo valueForKey:key]) {
        value = [[activeThemeInfo valueForKey:key] floatValue];
    }
    else {
        value = [[defaultThemeInfo valueForKey:key] floatValue];
    }
    return value;
}

static CGFloat floatForPermaKey(NSString* key) {
    CGFloat value;
    value = [[permaPrefs valueForKey:key] floatValue];
    return value;
}

static CGFloat alphaValueForActiveKey(NSString* key) {
    CGFloat value;
    if ([activeThemeInfo valueForKey:key]) {
        value = [[activeThemeInfo valueForKey:key] floatValue];
    }
    else {
        value = 1;
    }
    return value;
}

static CGSize bigSizeFromSize(CGSize size) {
    CGFloat width = floatForPermaKey(@"BigBubbleWidth");
    if (width == 0) {
        width = 270.0;
    }
    CGSize result;
    result.width = width;
    result.height = (width / size.width) * size.height;
    return result;
}

static BOOL isColourVeryLight(UIColor* col) {
    if (! col) {
        return NO;
    }
    const CGFloat* componentColors = CGColorGetComponents(col.CGColor);
    CGFloat darknessScore = (componentColors[0] * 0.299) + (componentColors[1] * 0.587) + (componentColors[2] * 0.114);
    return darknessScore >= 0.8;
}

static BOOL isColourVeryDark(UIColor* col) {
    if (! col) {
        return NO;
    }
    const CGFloat* componentColors = CGColorGetComponents(col.CGColor);
    CGFloat darknessScore = (componentColors[0] * 0.299) + (componentColors[1] * 0.587) + (componentColors[2] * 0.114);
    return darknessScore <= 0.3;
}

static BOOL isColourDark(UIColor* col) {
    if (! col) {
        return NO;
    }
    const CGFloat* componentColors = CGColorGetComponents(col.CGColor);
    CGFloat darknessScore = (componentColors[0] * 0.299) + (componentColors[1] * 0.587) + (componentColors[2] * 0.114);
    return darknessScore <= 0.5;
}

static NSArray *coloursForContactWithName(NSString* name, BOOL isSMS) {
    BOOL isGrad = [[contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ Gradient", name]] boolValue];
    UIColor* col1 = nil;
    UIColor* col2 = nil;
    if (isGrad) {
        if ([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ TopColour", name]]) {
            col1 = UIColorFromHexString([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ TopColour", name]]);
            if ([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ TopColourAlpha", name]]) {
                col1 = [col1 colorWithAlphaComponent:[[contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ TopColourAlpha", name]] floatValue]];
            }
        }

        if ([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ BottomColour", name]]) {
            col2 = UIColorFromHexString([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ BottomColour", name]]);
            if ([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ BottomColourAlpha", name]]) {
                col2 = [col2 colorWithAlphaComponent:[[contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ BottomColourAlpha", name]] floatValue]];
            }
        }
    }
    else {
        if ([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ BubbleColour", name]]) {
            col1 = col2 = UIColorFromHexString([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ BubbleColour", name]]);
            if ([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ BubbleColourAlpha", name]]) {
                col1 = col2 = [col1 colorWithAlphaComponent:[[contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ BubbleColourAlpha", name]] floatValue]];
            }
        }
    }
    if (! col1 || ! col2) {
        return nil;
    }
    return [NSArray arrayWithObjects:col1, col2, nil];
}

static UIColor *textColourForContactWithName(NSString* name, BOOL isSMS) {
    if ([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ TextColour", name]]) {
        return UIColorFromHexString([contactSpecificColours valueForKey:[NSString stringWithFormat:@"%@ TextColour", name]]);
    }
    else {
        return nil;
    }
}

static UIColor *brightnessAlteredColour(UIColor* color, CGFloat amount) {
    if (! color) {
        return nil;
    }

    CGFloat hue, saturation, brightness, alpha;
    if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        brightness += (amount-1.0);
        brightness = MAX(MIN(brightness, 1.0), 0.0);
        return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    }

    CGFloat white;
    if ([color getWhite:&white alpha:&alpha]) {
        white += (amount-1.0);
        white = MAX(MIN(white, 1.0), 0.0);
        return [UIColor colorWithWhite:white alpha:alpha];
    }

    return nil;
}

static UIColor *darkenedColourFromColour(UIColor* col) {
    return brightnessAlteredColour(col, 0.6);
}

static UIColor *lightenedColourFromColour(UIColor* col) {
    return brightnessAlteredColour(col, 1.5);
}

static NSString *localisedStringForKey(NSString* key) {
    return [[NSBundle bundleWithPath:@"/Library/PreferenceBundles/MCProPrefs.bundle"] localizedStringForKey:key value:key table:nil];
}

static void activateThemeForContactWithName(NSString* name) {
    NSString* themeNameToActivate;
    if ([convoSpecificThemes valueForKey:name]) {
        themeNameToActivate = [convoSpecificThemes valueForKey:name];
    }
    else if (isDarkModeActive && boolForPermaKey(@"DarkModeScheduled")) {
        themeNameToActivate = darkModeThemeName;
    }
    else {
        themeNameToActivate = fallbackThemeName;
    }

    NSString* pathToThemePlist = [NSString stringWithFormat:@"%@/%@/Theme.plist", themesBaseDirectory, themeNameToActivate];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToThemePlist]) {
        activeThemeInfo = [NSDictionary dictionaryWithContentsOfFile:pathToThemePlist];
    }
    else {
        NSString* pathToDefaultThemePlist = [NSString stringWithFormat:@"%@/Default/Theme.plist", themesBaseDirectory];
        activeThemeInfo = [NSDictionary dictionaryWithContentsOfFile:pathToDefaultThemePlist];
    }
}

static void updatePrefs() {
    contactSpecificColours = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@.%@.plist", prefsBaseDirectory, contactsPrefsName]];
    convoSpecificThemes = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@.%@.plist", prefsBaseDirectory, convosPrefsName]];
    permaPrefs = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@.%@.plist", prefsBaseDirectory, permaPrefsName]];
    fallbackThemeName = [permaPrefs valueForKey:@"ActiveTheme"];
    fallbackThemeInfo = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/Theme.plist", themesBaseDirectory, fallbackThemeName]];
    darkModeThemeName = fallbackThemeName;
    if ([permaPrefs valueForKey:@"DarkModeTheme"]) {
        if (! [[permaPrefs valueForKey:@"DarkModeTheme"] isEqualToString:@""]) {
            darkModeThemeName = [permaPrefs valueForKey:@"DarkModeTheme"];
        }
    }
    if (! activeThemeInfo) {
        activeThemeInfo = fallbackThemeInfo;
    }
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
    updatePrefs();
}

static NSDate *todaysDateFromString(NSString* time) {
    NSArray* array = [time componentsSeparatedByString:@":"];
    NSCalendar* cal = [NSCalendar currentCalendar];
    NSDateComponents* comp;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (IS_IOS_(8,0)) {
        comp = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[NSDate date]];
    }
    else {
        comp = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    }
#pragma clang diagnostic pop
    [comp setHour:[array[0] integerValue]];
    [comp setMinute:[array[1] integerValue]];
    return [cal dateFromComponents:comp];
}

static void updateDarkModeStatus() {
    BOOL isDarkModeBeingScheduled = boolForPermaKey(@"DarkModeScheduled");
    if (isDarkModeBeingScheduled) {
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];

        NSString* fromTimeString = stringForPermaKey(@"DarkModeScheduleFromTime");
        NSDate* darkModeActiveFromTime = todaysDateFromString(fromTimeString);

        NSString* toTimeString = stringForPermaKey(@"DarkModeScheduleToTime");
        NSDate* darkModeActiveToTime = todaysDateFromString(toTimeString);

        NSDate* now = [NSDate date];

        if ([darkModeActiveToTime compare:darkModeActiveFromTime] != NSOrderedDescending) {  // To before from
            if ([now compare:darkModeActiveFromTime] != NSOrderedAscending || [now compare:darkModeActiveToTime] != NSOrderedDescending) {   // now after from or before to
                isDarkModeActive = YES;
                //NSLog(@"BEFORE TO OR AFTER FROM");
            }
            else {
                isDarkModeActive = NO;
            }
        }
        else { // to after from
            if ([now compare:darkModeActiveToTime] != NSOrderedDescending && [now compare:darkModeActiveFromTime] != NSOrderedAscending) {  // now between from and to
                isDarkModeActive = YES;
                //NSLog(@"BETWEEN FROM AND TO");
            }
            else {
                isDarkModeActive = NO;
            }
        }
    }
    else {
        isDarkModeActive = boolForPermaKey(@"DarkMode");
    }

    isDarkModeActiveForCouria = isDarkModeActive;

    if (! ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.MobileSMS"] || [[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.mobilesms.compose"] || [[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.intelliborn.mpviewservice"])) {
        isValidApplicationForDarkMode = NO;
    }
    else {
        isValidApplicationForDarkMode = YES;
    }

    if (! isValidApplicationForDarkMode) {
        isDarkModeActive = NO;
    }

    NSInteger darkModeType = intForPermaKey(@"DarkMode");

    if (boolForPermaKey(@"DarkModeScheduled")) {
        darkModeType = 1;
    }

    if (darkModeType == 2) {
        darkModeBackgroundColour = colourForPermaKey(@"CustomDMBackgroundColour");
        darkModeForegroundColour = colourForPermaKey(@"CustomDMForegroundColour");
        darkModeBrightForegroundColour = colourForPermaKey(@"CustomDMBrightColour");
    }
    else {
        darkModeBackgroundColour = [UIColor colorWithRed:31.0/255.0 green:31.0/255.0 blue:28.0/255.0 alpha:1];
        darkModeForegroundColour = [UIColor colorWithWhite:1 alpha:0.3];
        darkModeBrightForegroundColour = UIColorFromHexString(@"#FFFFFF");
    }
}

/*
   NSObject *blurObj = [NSObject new];

   %hook CKGradientView

   -(void)setEffectView:(UIView *)arg1 {
    %orig;
    arg1.hidden = YES;
   }

   - (id)initWithFrame:(CGRect)arg1 {
    UIView *o = %orig;
    _UIBackdropView *v = [[_UIBackdropView alloc] initWithFrame:arg1 autosizesToFitSuperview:YES settings:[_UIBackdropViewSettings settingsForStyle:0]];
    [o addSubview:v];
    objc_setAssociatedObject(blurObj, (__bridge void *)self, v, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return o;
   }

   - (void)setColors:(NSArray *)arg1 {
    %orig;
    //_UIBackdropView *v = (_UIBackdropView *)objc_getAssociatedObject(blurObj, (__bridge void *)self);
    //[v transitionToColor:[[arg1 objectAtIndex:0] colorWithAlphaComponent:0.2]];
   }

   %end
 */

%hook CKTranscriptStatusController

-(void)setConversation:(id)arg1 {
    if (arg1) {
        activeMessageService = nil;

        CKConversation* conversationForThisTranscriptView = arg1;

        NSString* stringForLoadingTheme;

        if (conversationForThisTranscriptView.recipient != nil) {
            stringForLoadingTheme = conversationForThisTranscriptView.recipient.fullName;
            activeConvoIsGroup = NO;
            activeConvoName = [[conversationForThisTranscriptView.name componentsSeparatedByString:@" "] objectAtIndex:0];
        }
        else if (conversationForThisTranscriptView.recipients != nil && [conversationForThisTranscriptView.recipients count] != 0) {
            stringForLoadingTheme = @"Group";
            activeConvoIsGroup = YES;
            activeConvoName = @"Group";
        }
        else {
            stringForLoadingTheme = fallbackThemeName;
            activeConvoIsGroup = NO;
            activeConvoName = nil;
        }
        activateThemeForContactWithName(stringForLoadingTheme);

        /*  NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/MCPro/cache/services.plist"];
           if(!dic)
            dic = [[NSMutableDictionary alloc] init];

           activeConversationID = stringForLoadingTheme;

           if([dic valueForKey:stringForLoadingTheme]) {
            activeMessageServiceID = [[dic valueForKey:activeConversationID] boolValue];
            if(activeMessageServiceID)
              activeMessageService = [%c(IMService) smsService];
            else
              activeMessageService = [%c(IMService) iMessageService];
           }
           else {
            activeConversation = conversationForThisTranscriptView;

            activeMessageService = activeConversation.preferredService;

            if([activeMessageService isEqual:[%c(IMService) iMessageService]])
              activeMessageServiceID = 0;
            else
              activeMessageServiceID = 1;

            [dic setValue:[NSNumber numberWithInt:activeMessageServiceID] forKey:activeConversationID];
            [dic writeToFile:@"/var/mobile/Library/MCPro/cache/services.plist" atomically:YES];
           }*/
    }
    %orig;
}

%end

%hook CKTranscriptController

-(void)setConversation:(CKConversation*)arg1 {
    CKConversation* conversationForThisTranscriptView = arg1;
    NSString* stringForLoadingTheme;
    if (conversationForThisTranscriptView.recipient != nil) {
        stringForLoadingTheme = conversationForThisTranscriptView.recipient.fullName;
        activeConvoIsGroup = NO;
        activeConvoName = [[conversationForThisTranscriptView.name componentsSeparatedByString:@" "] objectAtIndex:0];
    }
    else if (conversationForThisTranscriptView.recipients != nil && [conversationForThisTranscriptView.recipients count] != 0) {
        stringForLoadingTheme = @"Group";
        activeConvoIsGroup = YES;
        activeConvoName = @"Group";
    }
    else {
        stringForLoadingTheme = fallbackThemeName;
        activeConvoIsGroup = NO;
        activeConvoName = nil;
    }
    activateThemeForContactWithName(stringForLoadingTheme);
    //[self _updateBackPlacardSubviews];
    return %orig;
}

%end

@interface UIView (chew)
-(void) _setDrawsAsBackdropOverlayWithBlendMode:(long)a;
@end

//------------------------  CONVO SPECIFIC COLOURS  --------------------------//

%hook CKBalloonView
%property (nonatomic, retain) NSString *senderName;
-(void)bogus {
    self.senderName = @"";
}
%end

%hook CKTranscriptBalloonCell

%property (nonatomic, assign) BOOL wantsContactPic;

-(void) configureForChatItem:(CKChatItem*)arg1 { // 8
    BOOL wantsContactPic = NO;
    if (! boolForActiveKey(@"FlatEdges")) {
        BOOL fromMe = arg1.IMChatItem.isFromMe;
        wantsContactPic = (fromMe && boolForPermaKey(@"MyContactPics")) || (! fromMe && ! activeConvoIsGroup && boolForPermaKey(@"SingleContactPics")) || (! fromMe && IS_IOS_(9,0) && activeConvoIsGroup && !boolForPermaKey(@"GroupContactPics"));
        if (wantsContactPic && arg1.hasTail) {
            if(IS_IOS_(9,0)) {
                if(!self.avatarView) {
                    CKAvatarView *av = [[%c(MCAvatarView) alloc] initWithContact:arg1.contact];
                    [self.subviews[0] addSubview:av];
                    self.avatarView = av;
                }
            }
            else {
                CGFloat d = [[%c(CKUIBehavior) sharedBehaviors] transcriptContactImageDiameter];
                if(arg1.IMChatItem.sender.person._recordID != 0) {
                    self.contactImage = [CKAddressBook transcriptContactImageOfDiameter:d forRecordID:arg1.IMChatItem.sender.person._recordID];
                }
            }
        }
        else {
            if(IS_IOS_(9,0)) {
                [self.avatarView removeFromSuperview];
                self.avatarView = NULL;
            }
            else {
                CGFloat d = [[%c(CKUIBehavior) sharedBehaviors] transcriptContactImageDiameter];
                UIGraphicsBeginImageContext(CGSizeMake(d, d));
                self.contactImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
        }
    }
    self.wantsContactPic = wantsContactPic;
    %orig;
    CKBalloonChatItem* item = (CKBalloonChatItem*)arg1;
    NSString* nameOfSender = item.sender.fullName;
    self.balloonView.senderName = nameOfSender;
}

-(void) setContactImage:(id)a {
    if ((self.wantsContactPic && a != nil) || ! self.wantsContactPic) {
        %orig;
    }
}

- (BOOL)wantsContactImageLayout {
    return IS_IOS_(9,0) ? self.wantsContactPic : %orig;
}

- (void)setWantsContactImageLayout:(BOOL)arg1 {
    %orig(IS_IOS_(9,0) ? self.wantsContactPic : arg1);
}

-(void) configureForRow:(id)arg1 {   // iOS 7
    %orig;
    CKTranscriptDataRow* row = arg1;
    NSString* nameOfSender = row.message.sender.fullName;
    self.balloonView.senderName = nameOfSender;
}

%end

%hook CKTranscriptTypingIndicatorCell

-(void)configureForRow:(CKTranscriptDataRow*)row {
    %orig;
    self.typingIndicatorLayer.senderName = row.message.sender.fullName;
}

%end

%hook CKColoredBalloonView

-(id)gradientView {
    CKGradientView* g = %orig;
    if (g != nil) {
        NSArray* cols = coloursForContactWithName(self.senderName, NO);
        if (cols != nil) {
            [g setColors:cols];
        }
        ///TODO FIX THIS???
        /*    else if (self.color == 0 && [[%c(CKUIBehavior) sharedBehaviors] green_balloonColors] != nil) {
                LOG(@"3");
                [g setColors:[[%c(CKUIBehavior) sharedBehaviors] green_balloonColors]];
            }
            else if (self.color == 1 && [[%c(CKUIBehavior) sharedBehaviors] blue_balloonColors] != nil) {
                LOG(@"4");
                [g setColors:[[%c(CKUIBehavior) sharedBehaviors] blue_balloonColors]];
            }
            else if ([[%c(CKUIBehavior) sharedBehaviors] gray_balloonColors] != nil){
                LOG(@"5");
                [g setColors:[[%c(CKUIBehavior) sharedBehaviors] gray_balloonColors]];
            }*/
    }
    return g;
}

%end

%hook CKContactBalloonView

-(void)prepareForDisplay {
    %orig;
    [self layoutSubviews]; //FIX FOR TEXT POSITIONS
}

%end

%hook CKTextBalloonView

-(void)prepareForDisplay {
    %orig;
    [self layoutSubviews]; //FIX FOR TEXT POSITIONS
}

-(id) textView {
    UITextView* view = %orig;
    UIColor* col = textColourForContactWithName(self.senderName, NO);
    if (col) {
        view.textColor = col;
    }
    else if (self.color == 0) {
        view.textColor = [[%c(CKUIBehavior) sharedBehaviors] green_balloonTextColor];
    }
    else if (self.color == 1) {
        view.textColor = [[%c(CKUIBehavior) sharedBehaviors] blue_balloonTextColor];
    }
    else {
        view.textColor = [[%c(CKUIBehavior) sharedBehaviors] gray_balloonTextColor];
    }

    return view;
}

%end

//----------------------------------------------------------//

%hook CKBalloonView

- (BOOL)isFilled {
    return ! boolForActiveKey(@"BubbleOutlineOnly");
}

-(BOOL) hasTail {
    NSInteger hideTails = intForActiveKey(@"BubbleTails");
    if (hideTails == 1) {
        return %orig;
    }
    else if (hideTails == 2) {
        return YES;
    }
    else if (hideTails == 3) {
        return NO;
    }
    else {
        return %orig;
    }
}

-(BOOL) canUseOpaqueMask {
    if (boolForActiveKey(@"BubbleOutlineOnly") || intForActiveKey(@"BackgroundType") != 0) {
        return NO;
    }
    else {
        return %orig;
    }
}

%end

%hook CKUIBehavior

//// BIGBUBBLES - @sticktron
- (CGSize)thumbnailFillSizeForImageSize:(CGSize)s {
    CGSize size = %orig;
    if (boolForPermaKey(@"BigBubbles") && ! IS_IPAD) {
        size = bigSizeFromSize(size);
    }
    return size;
}

-(id) chevronImage {
    UIImage* o = %orig;
    o = [o imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return o;
}

-(id) transcriptBackgroundColor {
    if (intForActiveKey(@"BackgroundType") == 0) {
        return colourForActiveKey(@"BackgroundColour");
    }
    else if (intForActiveKey(@"BackgroundType") == 2 || intForActiveKey(@"BackgroundType") == 3) {
        return [colourForActiveKey(@"BackgroundOverlayColour") colorWithAlphaComponent:floatForActiveKey(@"BackgroundOverlayColourAlpha")];
    }
    else {
        return [UIColor clearColor];
    }
}

-(id) transcriptTextColor {
    return [colourForActiveKey(@"InfoText") colorWithAlphaComponent:floatForActiveKey(@"InfoTextAlpha")];
}

-(id) appTintColor {
    return colourForPermaKey(@"AppTint");
}

//// GREEN

-(id) green_balloonColors {
    UIColor* col1;
    UIColor* col2;
    if (boolForActiveKey(@"SMSGrad")) {
        col1 = [colourForActiveKey(@"SMSTopBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"SMSTopBubbleAlpha")];
        col2 = [colourForActiveKey(@"SMSBottomBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"SMSBottomBubbleAlpha")];
    }
    else {
        col1 = col2 = [colourForActiveKey(@"SMSBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"SMSBubbleAlpha")];
    }

    return [NSArray arrayWithObjects:col1, col2, nil];
}

-(id) green_unfilledBalloonColor {
    UIColor* col;
    if (boolForActiveKey(@"SMSGrad")) {
        col = colourForActiveKey(@"SMSBottomBubble");
    }
    else {
        col = colourForActiveKey(@"SMSBubble");
    }

    return col;
}

-(id) green_balloonTextColor {
    return colourForActiveKey(@"SMSText");
}

-(id) green_balloonTextLinkColor {
    return colourForActiveKey(@"SMSText");
}

-(id) green_sendButtonColor {
    UIColor* col;
    if (boolForActiveKey(@"SMSGrad")) {
        col = colourForActiveKey(@"SMSBottomBubble");
    }
    else {
        col = colourForActiveKey(@"SMSBubble");
    }
    return col;
}

-(id) green_recipientTextColor {
    UIColor* col;
    if (boolForActiveKey(@"SMSGrad")) {
        col = colourForActiveKey(@"SMSBottomBubble");
        if (isColourVeryLight(col)) {
            col = darkenedColourFromColour(col);
        }
    }
    else {
        col = colourForActiveKey(@"SMSBubble");
        if (isColourVeryLight(col) && ! isDarkModeActive) {
            col = darkenedColourFromColour(col);
        }
        else if (isColourVeryDark(col) && isDarkModeActive) {
            col = lightenedColourFromColour(col);
        }
    }
    return col;
}

//// BLUE

-(id) blue_balloonColors {
    UIColor* col1;
    UIColor* col2;
    if (boolForActiveKey(@"IMGrad")) {
        col1 = [colourForActiveKey(@"IMTopBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"IMTopBubbleAlpha")];
        col2 = [colourForActiveKey(@"IMBottomBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"IMBottomBubbleAlpha")];
    }
    else {
        col1 = col2 = [colourForActiveKey(@"IMBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"IMBubbleAlpha")];
    }

    return [NSArray arrayWithObjects:col1, col2, nil];
}

-(id) blue_unfilledBalloonColor {
    UIColor* col;
    if (boolForActiveKey(@"IMGrad")) {
        col = colourForActiveKey(@"IMBottomBubble");
    }
    else {
        col = colourForActiveKey(@"IMBubble");
    }

    return col;
}

-(id) blue_balloonTextColor {
    return colourForActiveKey(@"IMText");
}

-(id) blue_balloonTextLinkColor {
    return colourForActiveKey(@"IMText");
}

-(id) blue_sendButtonColor {
    UIColor* col;
    if (boolForActiveKey(@"IMGrad")) {
        col = colourForActiveKey(@"IMBottomBubble");
    }
    else {
        col = colourForActiveKey(@"IMBubble");
    }
    return col;
}

-(id) blue_recipientTextColor {
    UIColor* col;
    if (boolForActiveKey(@"IMGrad")) {
        col = colourForActiveKey(@"IMBottomBubble");
        if (isColourVeryLight(col)) {
            col = darkenedColourFromColour(col);
        }
    }
    else {
        col = colourForActiveKey(@"IMBubble");
        if (isColourVeryLight(col) && ! isDarkModeActive) {
            col = darkenedColourFromColour(col);
        }
        else if (isColourVeryDark(col) && isDarkModeActive) {
            col = lightenedColourFromColour(col);
        }
    }
    return col;
}

//// GREY

-(id) gray_balloonColors {
    UIColor* col1;
    UIColor* col2;
    if (boolForActiveKey(@"OtherGrad")) {
        col1 = [colourForActiveKey(@"OtherTopBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"OtherTopBubbleAlpha")];
        col2 = [colourForActiveKey(@"OtherBottomBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"OtherBottomBubbleAlpha")];
    }
    else {
        col1 = col2 = [colourForActiveKey(@"OtherBubble") colorWithAlphaComponent:alphaValueForActiveKey(@"OtherBubbleAlpha")];
    }

    return [NSArray arrayWithObjects:col1, col2, nil];
}

-(id) gray_unfilledBalloonColor {
    UIColor* col;
    if (boolForActiveKey(@"OtherGrad")) {
        col = colourForActiveKey(@"OtherBottomBubble");
    }
    else {
        col = colourForActiveKey(@"OtherBubble");
    }

    return col;
}

-(id) gray_balloonTextColor {
    return colourForActiveKey(@"OtherText");
}

-(id) gray_balloonTextLinkColor {
    return colourForActiveKey(@"OtherText");
}

-(id) gray_recipientTextColor {  // DARK MODE
    if (isDarkModeActive) {
        return darkModeBrightForegroundColour;
    }
    else {
        return %orig;
    }
}

//-----------------------------------------------------------//

-(BOOL) canShowContactPhotosInConversationList {
    return boolForPermaKey(@"ListContactPics");
}

-(BOOL) useContactPhotosInConversationList {
    return boolForPermaKey(@"ListContactPics");
}

-(BOOL) shouldShowContactPhotosInConversationList {  //8
    return boolForPermaKey(@"ListContactPics");
}

-(BOOL) shouldShowContactPhotosInTranscript {
    if (activeConvoIsGroup) {
        return ! boolForPermaKey(@"GroupContactPics") && ! boolForActiveKey(@"FlatEdges");
    }
    else {
        return boolForPermaKey(@"SingleContactPics");
    }
}

-(CGFloat) transcriptContactImageDiameter {
    CGFloat rad = floatForPermaKey(@"CPicRadius");
    if (rad == 0) {
        rad = %orig;
    }
    return rad;
}

-(CGFloat) conversationListMultipleContactsImageDiameter {
    CGFloat rad = floatForPermaKey(@"CPicRadiusList");
    rad /= 1.67;
    if (rad == 0) {
        rad = %orig;
    }
    return rad;
}

-(CGFloat) conversationListContactImageDiameter {
    CGFloat rad = floatForPermaKey(@"CPicRadiusList");
    if (rad == 0) {
        rad = %orig;
    }
    return rad;
}

-(CGFloat) conversationListRowHeight {
    CGFloat height = floatForPermaKey(@"CPicRadiusList");

    if (height == 0) {
        height = %orig;
    }
    else {
        height += 15;
    }

    if (height > %orig) {
        return height;
    }
    else {
        return %orig;
    }
}
/* 7
-(CGFloat) rightBalloonMaxWidth {
    CGFloat width = floatForActiveKey(@"BubbleWidth");
    if (width == 0) {
        width = 231;
    }
    return width;
}

-(CGFloat) leftBalloonMaxWidth {
    CGFloat width = floatForActiveKey(@"BubbleWidth");
    if (width == 0) {
        width = 231;
    }
    return width;
}
*/

-(CGFloat)rightBalloonMaxWidthForEntryContentViewWidth:(CGFloat)arg1 {
    CGFloat per = floatForActiveKey(@"BubbleWidthPercent");
    if(per == 0)
        per = 70;
    per += 30;
    if(boolForActiveKey(@"FlatEdges"))
        per += 20;
    return %orig*(per/100);
}

-(CGFloat)leftBalloonMaxWidthForTranscriptWidth:(CGFloat)arg1 marginInsets:(UIEdgeInsets)arg2 {
    CGFloat per = floatForActiveKey(@"BubbleWidthPercent");
    if(per == 0)
        per = 70;
    per += 30;
    if(boolForActiveKey(@"FlatEdges"))
        per += 20;
    return %orig*(per/100);
}

%end

%hook CKTypingIndicatorLayer

%property (nonatomic, retain) NSString *senderName;

- (id)thinkingDot {
    CALayer* dot = %orig;
    dot.backgroundColor = [self newTextColour];

    if (boolForActiveKey(@"FlatEdges")) {
        CGRect frame = dot.frame;
        frame.origin.x += 6;
        dot.frame = frame;
    }
    return dot;
}

-(id) largeBubble {
    CALayer* b = %orig;
    if (boolForActiveKey(@"BubbleOutlineOnly")) {
        b.borderColor = ((UIColor*)[[[%c(CKUIBehavior) sharedBehaviors] gray_balloonColors] objectAtIndex:1]).CGColor;
        b.backgroundColor = [UIColor clearColor].CGColor;
        b.borderWidth = 1;
    }
    else {
        b.backgroundColor = [self newBubbleColour];
    }

    if (boolForActiveKey(@"FlatEdges")) {
        CGRect frame = b.frame;
        frame.size.width = 75;
        frame.origin.x = 3.5;
        b.frame = frame;
    }
    return b;
}

-(id) mediumBubble {
    CALayer* b = %orig;
    if (boolForActiveKey(@"BubbleOutlineOnly")) {
        b.borderColor =  [self newBubbleColour];
        b.backgroundColor = [UIColor clearColor].CGColor;
        b.borderWidth = 1;
    }
    else {
        b.backgroundColor = [self newBubbleColour];
    }
    return b;
}

-(id) smallBubble {
    CALayer* b = %orig;
    if (boolForActiveKey(@"BubbleOutlineOnly")) {
        b.borderColor = [self newBubbleColour];
        b.backgroundColor = [UIColor clearColor].CGColor;
        b.borderWidth = 1;
    }
    else {
        b.backgroundColor = [self newBubbleColour];
    }

    return b;
}

%new -(CGColor*)newBubbleColour {
    NSArray* cols = coloursForContactWithName(self.senderName, NO);

    if (cols) {
        return ((UIColor*)[cols objectAtIndex:1]).CGColor;
    }
    else {
        return ((UIColor*)[[[%c(CKUIBehavior) sharedBehaviors] gray_balloonColors] objectAtIndex:1]).CGColor;
    }
}

%new -(CGColor*)newTextColour {
    UIColor* col = textColourForContactWithName(self.senderName, NO);
    if (col) {
        return col.CGColor;
    }
    else {
        return ((UIColor*)[[%c(CKUIBehavior) sharedBehaviors] gray_balloonTextColor]).CGColor;
    }
}

%end

%hook CKTranscriptDataRow // < 8.4

- (BOOL)wantsContactImageLayout {
    if (boolForActiveKey(@"FlatEdges")) {
        return NO;
    }
    else {
        if (self.message.isFromMe) {
            return boolForActiveKey(@"MyContactPics");
        }
        else {
            if (activeConvoIsGroup) {
                return ! boolForActiveKey(@"GroupContactPics");
            }
            else {
                return boolForActiveKey(@"SingleContactPics");
            }
        }
    }
}

%end

@interface MCAvatarView : CKAvatarView
@end

%subclass MCAvatarView : CKAvatarView

-(void)setHidden:(BOOL)a {
    %orig(NO);
}

%end

%hook CKMessageEntryTextView

- (void)setPlaceholderText:(id)arg1  {
    if (boolForPermaKey(@"NameInPlaceholder")) {
        if (activeConvoName) {
            if (! [arg1 isEqualToString:@""]) {
                NSString* s = [NSString stringWithFormat:@"%@ %@ %@", arg1, localisedStringForKey(@"PLACEHOLDER_TO"), activeConvoName];
                %orig(s);
            }
            else {
                %orig;
            }
        }
        else {
            %orig;
        }
    }
    else {
        %orig;
    }
}

%end

/*
%hook CKMessageEntryView

   -(void)setSendButton:(id)o {
   UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(switchMessageService:)];
   longPress.minimumPressDuration = 0.75;
   [o addGestureRecognizer:longPress];
   %orig(o);
   }

   %new    - (void)switchMessageService:(UILongPressGestureRecognizer*)sender {
   if (sender.state == UIGestureRecognizerStateBegan && ![activeConvoName isEqual:@"Group"] && boolForPermaKey(@"HoldToSwitch")) {
    activeMessageServiceID = !activeMessageServiceID;
    if(activeMessageServiceID)
      activeMessageService = [%c(IMService) smsService];
    else
      activeMessageService = [%c(IMService) iMessageService];

    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/MCPro/cache/services.plist"];
    [dic setValue:[NSNumber numberWithInt:activeMessageServiceID] forKey:activeConversationID];
    [dic writeToFile:@"/var/mobile/Library/MCPro/cache/services.plist" atomically:YES];
    [self messageEntryContentViewDidChange:self.contentView];
   }
   }

%end
*/

%hook CKTranscriptLabelCell

-(void)layoutSubviewsForContents  {
    %orig;
    MSHookIvar<UILabel*>(self, "_label").textColor = [colourForActiveKey(@"InfoText") colorWithAlphaComponent:floatForActiveKey(@"InfoTextAlpha")];
}

%end

%hook MFModernAtomView

+(id)_SMSTintColor {
    UIColor* col;
    if (boolForActiveKey(@"SMSGrad")) {
        col = colourForActiveKey(@"SMSBottomBubble");
        if (isColourVeryLight(col)) {
            col = darkenedColourFromColour(col);
        }
    }
    else {
        col = colourForActiveKey(@"SMSBubble");
        if (isColourVeryLight(col) && ! isDarkModeActive) {
            col = darkenedColourFromColour(col);
        }
        else if (isColourVeryDark(col) && isDarkModeActive) {
            col = lightenedColourFromColour(col);
        }
    }
    return col;
}

+(id) _defaultTintColor {
    UIColor* col;
    if (boolForActiveKey(@"IMGrad")) {
        col = colourForActiveKey(@"IMBottomBubble");
        if (isColourVeryLight(col)) {
            col = darkenedColourFromColour(col);
        }
    }
    else {
        col = colourForActiveKey(@"IMBubble");
        if (isColourVeryLight(col) && ! isDarkModeActive) {
            col = darkenedColourFromColour(col);
        }
        else if (isColourVeryDark(col) && isDarkModeActive) {
            col = lightenedColourFromColour(col);
        }
    }
    return col;
}

%end

%hook CKBalloonImageView
-(UIEdgeInsets)alignmentRectInsets {
    // FOR FLAT EDGES
    UIEdgeInsets orig = %orig;
    CGFloat left = orig.left;
    CGFloat right = orig.right;

    if (boolForActiveKey(@"FlatEdges")) {
        if (left == 18) {
            left = 70;
        }
        if (right == 18) {
            right = 70;
        }
    }

    UIEdgeInsets newInsets = UIEdgeInsetsMake(orig.top, left, orig.bottom, right);
    return IS_IOS_(9,0) ? %orig : newInsets;
}
%end

%hook CKTranscriptBalloonCell

-(UIEdgeInsets)contentAlignmentInsets {
    UIEdgeInsets orig = %orig;
    CGFloat left = orig.left;
    CGFloat right = orig.right;

    if (boolForActiveKey(@"FlatEdges")) {
        if ((left == 10 && ! IS_IPAD) || (left == 19 && IS_IPAD)) {
            left = -45;
        }
        if ((right == 10 && ! IS_IPAD) || (right == 19 && IS_IPAD)) {
            right = -45;
        }
    }
    else if (boolForPermaKey(@"MyContactPics")) { // pre 8.4
        if ((right == 10 && ! IS_IPAD) || (right == 19 && IS_IPAD)) {
            right += [[%c(CKUIBehavior) sharedBehaviors] transcriptContactImageDiameter] + 3;
        }
    }

    UIEdgeInsets newInsets = UIEdgeInsetsMake(orig.top, left, orig.bottom, right);
    return IS_IOS_(9,0) ? %orig : newInsets;
}

%end

%hook CKTranscriptDataRow // iOS7

-(UIEdgeInsets)contentAlignmentInsets {
    UIEdgeInsets orig = %orig;
    CGFloat left = orig.left;
    CGFloat right = orig.right;

    if (boolForActiveKey(@"FlatEdges")) {
        if ((left == 10 && ! IS_IPAD) || (left == 19 && IS_IPAD)) {
            left = -45;
        }
        if ((right == 10 && ! IS_IPAD) || (right == 19 && IS_IPAD)) {
            right = -45;
        }
    }
    else if (boolForPermaKey(@"MyContactPics")) {
        if ((right == 10 && ! IS_IPAD) || (right == 19 && IS_IPAD)) {
            right += [[%c(CKUIBehavior) sharedBehaviors] transcriptContactImageDiameter] + 3;
        }
    }

    UIEdgeInsets newInsets = UIEdgeInsetsMake(orig.top, left, orig.bottom, right);
    return newInsets;
}

%end

%hook CKConversationListController

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;
    if (boolForPermaKey(@"HideSearchBar")) {
        UITableView* tv = MSHookIvar<UITableView*>(self, "_table");
        if(IS_IOS_(8,4)) {
            CGRect frame = tv.tableHeaderView.frame;
            frame.size.height = 0;
            tv.tableHeaderView.frame = frame;
            tv.tableHeaderView = tv.tableHeaderView;
        }
        else  {
            tv.tableHeaderView.hidden = YES;
        }
        if (tv.contentOffset.y == -20 || tv.contentOffset.y == -36) {
            tv.contentOffset = CGPointMake(0, -64);
        }
    }
}

- (CGFloat)heightForHeaderInTableView:(id)arg1 {
	if(boolForPermaKey(@"HideSearchBar"))
		return 0;
	else
		return %orig;
}

%end

//------------------- QUICKSWITCHER & GRAD/IMAGE BACKGROUND -------------------//

%hook CKTranscriptController

%property (nonatomic, retain) CHQuickSwitcher *quickSwitcher;
%property (nonatomic, retain) CAGradientLayer *gradientBackground;
%property (nonatomic, retain) UIImageView *backgroundImageView;

- (void)_updateBackPlacardSubviews {
    %orig;
    if (! boolForPermaKey(@"EclipseSupport")) {
        [self.entryView updateBackgroundColour];//FOR DARK MODE
    }
    UIView* view = self.view;
    self.collectionViewController.view.backgroundColor = [[%c(CKUIBehavior) sharedBehaviors] transcriptBackgroundColor];

    NSInteger bgType = intForActiveKey(@"BackgroundType");

    if(self.gradientBackground)
        [self.gradientBackground removeFromSuperlayer];

    if (bgType == 1) { // Gradient
        if(self.backgroundImageView)
        [self.backgroundImageView removeFromSuperview];

        self.gradientBackground = [CAGradientLayer layer];
        self.gradientBackground.frame = view.bounds;
        self.gradientBackground.bounds = view.bounds;
        self.gradientBackground.colors = [NSArray arrayWithObjects:(id)[colourForActiveKey(@"BackgroundTopColour") CGColor], (id)[colourForActiveKey(@"BackgroundBottomColour") CGColor], nil];
        [view.layer insertSublayer:self.gradientBackground atIndex:0];
    }
    else if (bgType == 2 || bgType == 3 || bgType == 4) { // IMAGE/WALL
        if (! self.backgroundImageView) {
            self.backgroundImageView = [[UIImageView alloc] initWithFrame:view.bounds];
            self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.backgroundImageView.clipsToBounds = YES;
            self.backgroundImageView.backgroundColor = [UIColor whiteColor];
        }

        CGFloat blurRadius = floatForActiveKey(@"BGBlurRadius");

        if (bgType == 2) { // WALLPAPER
            NSString* wallPath = @"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap";
            if (! [[NSFileManager defaultManager] fileExistsAtPath:wallPath]) {
                wallPath = @"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap";
            }
            UIImage* upToDateWallpaperImage = [UIImage imageWithContentsOfCPBitmapFile:wallPath flags:nil];
            NSData* upToDateWallpaperData = UIImageJPEGRepresentation(upToDateWallpaperImage, 1.0);
            NSData* cachedWallpaperData = [[NSFileManager defaultManager] contentsAtPath:@"/var/mobile/Library/MCPro/cache/Wall.jpeg"];
            UIImage* upToDateBlurredImage;
            if (! [cachedWallpaperData isEqual:upToDateWallpaperData]) {
                [UIImageJPEGRepresentation(upToDateWallpaperImage, 1.0) writeToFile:@"/var/mobile/Library/MCPro/cache/Wall.jpeg" atomically:YES];
                if (blurRadius != 0) {
                    upToDateBlurredImage = [upToDateWallpaperImage imageWithBlurRadius:blurRadius];
                    [UIImageJPEGRepresentation(upToDateBlurredImage, 1.0) writeToFile:@"/var/mobile/Library/MCPro/cache/Wall_blurred.jpeg" atomically:YES];
                }
            }
            else {
                upToDateBlurredImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/MCPro/cache/Wall_blurred.jpeg"];
            }

            if (blurRadius == 0) {
                self.backgroundImageView.image = upToDateWallpaperImage;
            }
            else {
                self.backgroundImageView.image = upToDateBlurredImage;
            }
        }
        else if (bgType == 3) { // Custom Image
            NSString * themeNameForPath = [activeThemeInfo valueForKey:@"themeName"];
            themeNameForPath = [themeNameForPath stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_-]+" options:0 error:nil];
            themeNameForPath = [regex stringByReplacingMatchesInString:themeNameForPath options:0 range:NSMakeRange(0, themeNameForPath.length) withTemplate:@""];
            if (blurRadius == 0) {
                self.backgroundImageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG.jpeg", themeNameForPath]];
            }
            else {
                self.backgroundImageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/MCPro/Themes/%@/BG_blurred.jpeg", themeNameForPath]];
            }
        }
        else if (bgType == 4) { // contact pic
            CFDataRef cfData = ABPersonCopyImageDataWithFormat([[self conversation].recipient abRecord], kABPersonImageFormatOriginalSize);
            NSData* data = (__bridge_transfer NSData*)cfData;
            UIImage* img = [UIImage imageWithData:data];
            self.backgroundImageView.image = img;
        }
        if (! [self.backgroundImageView isDescendantOfView:view]) {
            [view insertSubview:self.backgroundImageView atIndex:0];
        }
    }
    else {
        if(self.backgroundImageView)
            [self.backgroundImageView removeFromSuperview];
        if(self.gradientBackground)
            [self.gradientBackground removeFromSuperlayer];
    }
}

-(void) loadView {
    %orig;
    if (boolForPermaKey(@"QuickSwitch") && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        if (! self.quickSwitcher) {
            CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.width;
            CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.height;
            self.quickSwitcher = [[CHQuickSwitcher alloc] initWithFrame:CGRectMake(screenWidth-30, screenHeight/4, 60, 60) andTargetForButtons:self];
        }
        if (! [self.quickSwitcher isDescendantOfView:self.view]) {
            [self.view addSubview:self.quickSwitcher];
        }
    }
}

-(void) willRotateToInterfaceOrientation:(NSInteger)arg1 duration:(double)arg2 {    // <8.4
    CGFloat duration = arg2;
    if (self.quickSwitcher) {
        if (arg1 == UIDeviceOrientationPortrait || arg1 == UIDeviceOrientationPortraitUpsideDown) {
            CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
            CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:duration];
            self.quickSwitcher.frame = CGRectMake(screenWidth-30, screenHeight/4, 60, 60);
            [UIView commitAnimations];
        }
        else if (arg1 == UIDeviceOrientationLandscapeLeft || arg1 == UIDeviceOrientationLandscapeRight) {
            CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.width;
            CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.height;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:duration];
            self.quickSwitcher.frame = CGRectMake(screenWidth-30, screenHeight/4, 60, 60);
            [UIView commitAnimations];
        }
    }
    if (self.gradientBackground != nil) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        self.gradientBackground.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
        [UIView commitAnimations];
    }
    %orig;
}

-(void) viewDidLayoutSubviews {  // 8.4
    %orig;
    CGFloat duration = 0.2;
    if (self.quickSwitcher) {
        [self.view bringSubviewToFront:self.quickSwitcher];
        CGFloat screenHeight = self.view.frame.size.height;
        CGFloat screenWidth = self.view.frame.size.width;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        self.quickSwitcher.frame = CGRectMake(screenWidth-30, screenHeight/4, 60, 60);
        [UIView commitAnimations];
        NSArray* cl = [[%c(CKConversationList) sharedConversationList] conversations];
        NSInteger index = [cl indexOfObject:[self conversation]];
        if (index == cl.count-1) {
            [self.quickSwitcher setCanGoDown:NO];
        }
        else {
            [self.quickSwitcher setCanGoDown:YES];
        }
        if (index == 0) {
            [self.quickSwitcher setCanGoUp:NO];
        }
        else {
            [self.quickSwitcher setCanGoUp:YES];
        }
    }
    if (self.gradientBackground != nil) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        self.gradientBackground.frame = self.view.bounds;
        [UIView commitAnimations];
    }
    %orig;
}

-(void) _setupNewComposition {  // <8.4
    %orig;
    if (self.quickSwitcher != nil) {
        self.quickSwitcher.hidden = YES;
        self.quickSwitcher.alpha = 0;
    }
}

-(void) setupForNewRecipient {  // 8.4
    %orig;
    if (self.quickSwitcher != nil) {
        self.quickSwitcher.hidden = YES;
        self.quickSwitcher.alpha = 0;
    }
}

-(void) startSendAnimationForMessage:(id)arg1 {   // <8.4
    %orig;
    if (self.quickSwitcher != nil) {
        if (self.quickSwitcher.hidden) {
            self.quickSwitcher.hidden = NO;
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.2];
            self.quickSwitcher.alpha = 1;
            [UIView commitAnimations];
        }
    }
}

-(void) transitionFromNewMessageToConversation {  // 8.4
    %orig;
    if (self.quickSwitcher != nil) {
        if (self.quickSwitcher.hidden) {
            self.quickSwitcher.hidden = NO;
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.2];
            self.quickSwitcher.alpha = 1;
            [UIView commitAnimations];
        }
    }
}

%new - (void)nextConvo {
    NSArray* cl = [[%c(CKConversationList) sharedConversationList] conversations];
    NSInteger index = [cl indexOfObject:[self conversation]];
    index += 1;
    if (index < cl.count) {
        CKConversation* convo = [cl objectAtIndex:index];
        [self setConversation:convo];

        if ([convo.chat chatItems].count <= 4) {
            [convo performSelector:@selector(loadMoreMessages) withObject:convo afterDelay:0.1];
        }
    }
}

%new - (void)prevConvo {
    NSArray* cl = [[%c(CKConversationList) sharedConversationList] conversations];
    NSInteger index = [cl indexOfObject:[self conversation]];
    index -= 1;
    if (index >= 0) {
        CKConversation* convo = [cl objectAtIndex:index];
        [self setConversation:convo];

        if ([convo.chat chatItems].count <= 4) {
            [convo performSelector:@selector(loadMoreMessages) withObject:convo afterDelay:0.1];
        }
    }
}

%end

/*
   %hook CKConversation

   -(id)preferredService {
   if([activeConvoName isEqual:@"Group"] || !activeMessageService)
    return %orig;
   else
    return activeMessageService;
   }

   -(id)serviceDisplayName {
   if([activeConvoName isEqual:@"Group"] || !activeMessageService)
    return %orig;
   else
    return [activeMessageService __ck_displayName];
   }

   -(BOOL)buttonColor {
   if([activeConvoName isEqual:@"Group"] || !activeMessageService)
    return %orig;
   else
    return [activeMessageService __ck_displayColor];
   }

   %end
 */

//------------------- UNREPLIED INDICATORS -------------------//

%hook CKConversation
%property (nonatomic, assign) BOOL unrepliedTo;
-(void)bogusMethod {
    self.unrepliedTo = NO;
}
%end

%hook CKConversationListCell

%property (nonatomic, retain) UIView *unrepliedView;
%property (nonatomic, retain) CKConversation *associatedConversation;

-(void)layoutSubviews {
    %orig;

    //DARK MODE
    if (isDarkModeActive) {
        self.backgroundColor = darkModeBackgroundColour;
    }
    else if (isValidApplicationForDarkMode) {
        self.backgroundColor = [UIColor whiteColor];
    }

    UIImageView* chevron = MSHookIvar<UIImageView*>(self, "_chevronImageView");
    if (isDarkModeActive) {
        chevron.tintColor = darkModeForegroundColour;
    }
    else {
        chevron.tintColor = [[%c(CKUIBehavior) sharedBehaviors] lightGrayColor];
    }

    BOOL hideDate = boolForPermaKey(@"HideDates");
    UILabel* date = MSHookIvar<UILabel*>(self, "_dateLabel");
    if (hideDate) {
        date.hidden = YES;
    }
    else {
        date.hidden = NO;
    }

    BOOL hidePrev = boolForPermaKey(@"HidePreviews");
    UILabel* preview = MSHookIvar<UILabel*>(self, "_summaryLabel");
    if (hidePrev) {
        preview.hidden = YES;
    }
    else {
        preview.hidden = NO;
    }

    if (! boolForPermaKey(@"EclipseSupport")) {
        [MSHookIvar<UILabel*>(self, "_fromLabel") updateTextColour];
        [date updateTextColour];
        [preview updateTextColour];
    }

    UIColor* tintCol = [[%c(CKUIBehavior) sharedBehaviors] appTintColor];

    UIImageView* unread = MSHookIvar<UIImageView*>(self, "_unreadIndicatorImageView");
    if (unread) {
        unread.tintColor = tintCol;
        unread.image = [unread.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }

    BOOL ind = boolForPermaKey(@"UnrepliedIndicator");

    if (ind) {
        if (unread) {
            self.unrepliedView.frame = unread.frame;
        }
        if (self.associatedConversation.unrepliedTo) {
            self.unrepliedView.layer.borderColor = tintCol.CGColor;
        }
        else {
            self.unrepliedView.layer.borderColor = [UIColor clearColor].CGColor;
        }
    }
}

-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 {
    BOOL ind = boolForPermaKey(@"UnrepliedIndicator");
    UITableViewCell* o = %orig;
    if (ind) {
        self.unrepliedView = [[UIView alloc] initWithFrame:CGRectMake(8, 11.5, 12, 12)];
        self.unrepliedView.backgroundColor = [UIColor clearColor];
        self.unrepliedView.layer.cornerRadius = 6;
        self.unrepliedView.layer.borderWidth = 1.5f;
        self.unrepliedView.layer.borderColor = [UIColor clearColor].CGColor;
        [o insertSubview:self.unrepliedView atIndex:0];
    }
    return o;
}

-(void) setEditing:(BOOL)arg1 animated:(BOOL)arg2 {
    %orig;
    BOOL ind = boolForPermaKey(@"UnrepliedIndicator");
    if (ind) {
        if (arg1) {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3];
            self.unrepliedView.alpha = 0;
            [UIView commitAnimations];
        }
        else {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3];
            self.unrepliedView.alpha = 1;
            [UIView commitAnimations];
        }
    }
}

-(void) updateContentsForConversation:(CKConversation*)c {
    %orig;
    self.associatedConversation = c;
}

%end

%hook CKConversationListController

- (id)conversationList {
    CKConversationList* o = %orig;
    for (CKConversation* c in o.conversations) {
        if (IS_IOS_(8,0)) {
            if ([c.chat chatItems].count > 0) {
                IMMessageChatItem* item = [[c.chat chatItems] objectAtIndex:[c.chat chatItems].count-1];
                if ([item respondsToSelector:@selector(isFromMe)]) {
                    c.unrepliedTo = !item.isFromMe;
                }
            }
        }
        else {
            if (c.messages.count > 0) {
                CKIMMessage* m = [c.messages objectAtIndex:c.messages.count-1];
                if ([m respondsToSelector:@selector(isFromMe)]) {
                    c.unrepliedTo = ! m.isFromMe;
                }
            }
        }
    }
    return o;
}

-(void) deleteButtonPressedForIndexPath:(id)arg1 {
    %orig;
    [self performSelector:@selector(conversationList) withObject:self afterDelay:0.2];
}

%end

%hook CKEditableCollectionViewCell

-(void)setHighlighted:(bool)arg1 {
    %orig;
    if (arg1) {
        self.checkmark.image = [self.checkmark.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.checkmark.tintColor = [[%c(CKUIBehavior) sharedBehaviors] appTintColor];
    }
}

-(void) setSelected:(bool)arg1 {
    %orig;
    if (arg1) {
        self.checkmark.image = [self.checkmark.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.checkmark.tintColor = [[%c(CKUIBehavior) sharedBehaviors] appTintColor];
    }
}

%end

//------------------- HIDE SEPARATORS -------------------//

%hook CKConversationListController

-(void)viewWillAppear:(bool)arg1  {
    %orig;
    UITableView* table = MSHookIvar<UITableView*>(self, "_table");
    if (boolForPermaKey(@"HideSeparators")) {
        table.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else {
        table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    [self conversationList];
}

%end

//---------------------  DARK MODE ---------------------//

%group DARKMODE

UIStatusBar * currentStatusBar;

%hook UIApplication

-(id)init {
    [self updateForDarkMode];
    if (isValidApplicationForDarkMode) {
        [[%c(UIToolbarButton) appearance] setTintColor:[[%c(CKUIBehavior) sharedBehaviors] appTintColor]];
        [[%c(UINavigationButton) appearance] setTintColor:[[%c(CKUIBehavior) sharedBehaviors] appTintColor]];
    }
    return %orig;
}

-(id) keyWindow {
    UIWindow* o = %orig;
    [self updateForDarkMode];
    if (isValidApplicationForDarkMode) {
        o.tintColor = colourForPermaKey(@"AppTint");
    }
    return o;
}

%new -(void)updateForDarkMode {
    updateDarkModeStatus();

    NSInteger darkModeType = intForPermaKey(@"DarkMode");
    if (boolForPermaKey(@"DarkModeScheduled")) {
        darkModeType = 1;
    }

    if (isDarkModeActive) {
        [currentStatusBar setForegroundColor:darkModeBrightForegroundColour];
    }
    else if (isValidApplicationForDarkMode) {
        [currentStatusBar setForegroundColor:[UIColor blackColor]];
    }
}

%end

%hook UINavigationBar

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        NSInteger darkModeType = intForPermaKey(@"DarkMode");
        if (boolForPermaKey(@"DarkModeScheduled")) {
            darkModeType = 1;
        }
        if (darkModeType == 2) {
            [self setBarStyle:0];
            [self setBarTintColor:[darkModeBackgroundColour colorWithAlphaComponent:0.7]];
        }
        else {
            [self setBarStyle:1];
            [self setBarTintColor:nil];
        }
        [self setTitleTextAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:darkModeBrightForegroundColour, nil] forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName, nil]]];
    }
    else if (isValidApplicationForDarkMode) {
        [self setBarStyle:0];
        [self setBarTintColor:nil];
        [self setTitleTextAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[UIColor blackColor], nil] forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName, nil]]];
    }
}

%end

%hook UIToolbar

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        NSInteger darkModeType = intForPermaKey(@"DarkMode");
        if (boolForPermaKey(@"DarkModeScheduled")) {
            darkModeType = 1;
        }
        if (darkModeType == 2) {
            [self setBarStyle:0];
            [self setBarTintColor:[darkModeBackgroundColour colorWithAlphaComponent:0.7]];
        }
        else {
            [self setBarStyle:1];
            [self setBarTintColor:nil];
        }
    }
    else if (isValidApplicationForDarkMode) {
        [self setBarStyle:0];
        [self setBarTintColor:nil];
    }
}

%end

%hook UITabBar

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        NSInteger darkModeType = intForPermaKey(@"DarkMode");
        if (boolForPermaKey(@"DarkModeScheduled")) {
            darkModeType = 1;
        }
        if (darkModeType == 2) {
            [self setBarStyle:0];
            [self setBarTintColor:[darkModeBackgroundColour colorWithAlphaComponent:0.7]];
        }
        else {
            [self setBarStyle:1];
            [self setBarTintColor:nil];
        }
    }
    else if (isValidApplicationForDarkMode) {
        [self setBarStyle:0];
        [self setBarTintColor:nil];
    }
}

%end

%hook UISearchBar

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        self.backgroundColor = darkModeBackgroundColour;
        NSInteger darkModeType = intForPermaKey(@"DarkMode");
        if (boolForPermaKey(@"DarkModeScheduled")) {
            darkModeType = 1;
        }
        if (darkModeType == 2) {
            [self setBarStyle:0];
            [self setBarTintColor:darkModeBackgroundColour];
        }
        else {
            [self setBarStyle:1];
            [self setBarTintColor:nil];
        }
    }
    else if (isValidApplicationForDarkMode) {
        [self setBarStyle:0];
        [self setBarTintColor:nil];
        self.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    }
}

%end

%hook UITextInputTraits

-(UIKeyboardAppearance)keyboardAppearance {
    if (isDarkModeActive && (boolForPermaKey(@"DarkModeScheduled") || intForPermaKey(@"DarkMode") != 2)) {
        return UIKeyboardAppearanceDark;
    }
    else {
        return %orig;
    }
}

-(void) _setColorsToMatchTintColor:(id)arg1 {
    UIColor* col = [[%c(CKUIBehavior) sharedBehaviors] appTintColor];
    %orig(col);
}

%end

%hook UITableView

-(void)layoutSubviews {
    %orig;
    if (! [self isKindOfClass:%c(CKRecipientTableView)] && ! [self isKindOfClass:%c(UIPickerTableView)]) {
        if (isDarkModeActive) {
            [self setBackgroundColor:darkModeBackgroundColour];
            [self setTableHeaderBackgroundColor:darkModeBackgroundColour];
            [self setSeparatorColor:darkModeForegroundColour];
        }
        else if (isValidApplicationForDarkMode) {
            [self setBackgroundColor:[UIColor whiteColor]];
            [self setTableHeaderBackgroundColor:[UIColor whiteColor]];
            [self setSeparatorColor:[UIColor lightGrayColor]];
        }
    }
}

%end

%hook UITableViewCell

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        if (! [self isKindOfClass:%c(CKMultipleRecipientTableViewCell)] && ! [self isKindOfClass:%c(CKMultipleRecipientCollapsedTableViewCell)]) {
            self.backgroundView.backgroundColor = darkModeBackgroundColour;
            [self setBackgroundColor:darkModeBackgroundColour];
        }
        UIColor* col = darkModeBackgroundColour;
        if (isColourDark(col)) {
            col = brightnessAlteredColour(col, 1.1);
        }
        else {
            col = brightnessAlteredColour(col, 0.8);
        }
        MSHookIvar<UIColor*>(self, "_selectionTintColor") = col;
    }
    else {
        MSHookIvar<UIColor*>(self, "_selectionTintColor") = [UIColor lightGrayColor];
    }
}

%end

%hook ABContactView

-(id)backgroundColor {
    if (isDarkModeActive) {
        return darkModeBackgroundColour;
    }
    else {
        return %orig;
    }
}

%end

%hook CNContactView // IOS9

- (id)sectionBackgroundColor {
    if (isDarkModeActive) {
        return darkModeBackgroundColour;
    }
    else {
        return %orig;
    }
}

- (id)selectedCellBackgroundColor {
    if (isDarkModeActive) {
        return brightnessAlteredColour(darkModeBackgroundColour,1.2);
    }
    else {
        return %orig;
    }
}

%end

%hook CKTranscriptGroupHeaderView

- (void)layoutSubviews {
    %orig;
    if(isDarkModeActive) {
        if (intForPermaKey(@"DarkMode") == 2) {
            [self.backdropView transitionToSettings:[_UIBackdropViewSettings settingsForStyle:0]];
            [self.backdropView transitionToColor:[darkModeBackgroundColour colorWithAlphaComponent:0.7]];
        }
        else {
            [self.backdropView transitionToSettings:[_UIBackdropViewSettings settingsForStyle:1]];
        }
    }
}

%end

%hook CKTranscriptManagementNameField

- (id)backdropView {
    ((UIView*)%orig).hidden = isDarkModeActive;
    return %orig;
}

-(void)setBackgroundColor:(id)o {
    if (isDarkModeActive) {
        %orig(darkModeBackgroundColour);
    }
    else {
        %orig;
    }
}

- (id)fieldLabel {
    if(isDarkModeActive) {
        ((UILabel*)%orig).textColor = darkModeBrightForegroundColour;
    }
    else {
        ((UILabel*)%orig).textColor = [UIColor blackColor];
    }
    return %orig;
}

%end

%hook CKRecipientTableViewCell

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        ((UIView*)self).backgroundColor = [UIColor clearColor];
    }
    else if (isValidApplicationForDarkMode) {
        ((UIView*)self).backgroundColor = [UIColor whiteColor];
    }
}

%end

%hook UILabel

-(void)setTextColor:(id)col {
    if (isDarkModeActive && ([col isEqual:[UIColor blackColor]] || [col isEqual:[UIColor colorWithWhite:0 alpha:0.7]])) {
        %orig(darkModeBrightForegroundColour);
        self.tag = 38199;
    }
    else if (self.tag == 38199  && isValidApplicationForDarkMode && ! isDarkModeActive) {
        %orig([UIColor blackColor]);
    }
    else {
        if (self.tag == 38199 || self.tag == 10923) {
            self.tag = nil;
        }
        %orig;
    }
}

-(void) setBackgroundColor:(id)col {
    if (isDarkModeActive && [col isEqual:[UIColor whiteColor]]) {
        %orig([UIColor clearColor]);
    }
    else {
        %orig;
    }
}

%new -(void)updateTextColour {
    if (isDarkModeActive && ([self.textColor isEqual:[UIColor blackColor]] || [self.textColor isEqual:[UIColor colorWithWhite:0 alpha:0.7]] || self.tag == 38199)) {
        self.textColor = darkModeBrightForegroundColour;
        self.tag = 38199;
    }
    else if (isDarkModeActive && ([self.textColor isEqual:UIColorFromHexString(@"#8E8E93")] || self.tag == 10923)) {
        self.textColor = darkModeForegroundColour;
        self.tag = 10923;
    }
    else if (self.tag == 38199  && isValidApplicationForDarkMode && ! isDarkModeActive) {
        self.textColor = [UIColor blackColor];
    }
    else if (self.tag == 10923 && isValidApplicationForDarkMode && ! isDarkModeActive) {
        self.textColor = UIColorFromHexString(@"#8E8E93");
    }
}

%end

%hook UITextField

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        [self setTextColor:darkModeBrightForegroundColour];
    }
}

-(void) setTextColor:(id)col {
    if (isDarkModeActive && [col isEqual:[UIColor blackColor]]) {
        %orig(darkModeBrightForegroundColour);
    }
    else {
        %orig;
    }
}

-(void) setBackgroundColor:(id)col {
    if (isDarkModeActive && [col isEqual:[UIColor whiteColor]]) {
        %orig([UIColor clearColor]);
    }
    else {
        %orig;
    }
}

%end

%hook _UIDatePickerView

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    else if (isValidApplicationForDarkMode) {
        [self setBackgroundColor:[UIColor colorWithWhite:0.97 alpha:0.8]];
    }
}

%end

%hook UITableViewIndex

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        [self setIndexBackgroundColor:darkModeBackgroundColour];
    }
    else if (isValidApplicationForDarkMode) {
        [self setIndexBackgroundColor:[UIColor whiteColor]];
    }
}

%end
@interface CKMessageEntryView ()
-(BOOL) isTinctActive;
@end
static _UIBackdropViewSettings* defaultSettings;

%hook CKMessageEntryView

%new -(void)updateBackgroundColour {
    if (! defaultSettings) {
        defaultSettings = self.backdropView.inputSettings;
    }

    BOOL tinct;
    if ([self respondsToSelector:@selector(isTinctActive)]) {
        tinct = [self isTinctActive];
    }
    else {
        tinct = NO;
    }

    if (! tinct) {
        if (isDarkModeActive) {
            if(IS_IOS_(8,0)) {
                self.audioButton.tintColor = darkModeForegroundColour;
            }
            NSInteger darkModeType = intForPermaKey(@"DarkMode");
            self.coverView.alpha = 0.1;
            if (darkModeType == 2) {
                [self.backdropView transitionToSettings:[_UIBackdropViewSettings settingsForStyle:0]];
                [self.backdropView transitionToColor:[darkModeBackgroundColour colorWithAlphaComponent:0.7]];
                if (isColourDark(darkModeBackgroundColour)) {
                    self.coverView.fillColor = [UIColor whiteColor];
                }
                else {
                    self.coverView.fillColor = [UIColor blackColor];
                }
            }
            else {
                [self.backdropView transitionToSettings:[_UIBackdropViewSettings settingsForStyle:1]];
                self.coverView.fillColor = [UIColor whiteColor];
            }
        }
        else if (isValidApplicationForDarkMode) {
            if(IS_IOS_(8,0)) {
                self.audioButton.tintColor = UIColorFromHexString(@"#8E8E93");
            }
            self.photoButton.tintColor = UIColorFromHexString(@"#8E8E93");
            self.coverView.alpha = 1;
            self.coverView.fillColor = [UIColor whiteColor];
            [self.backdropView transitionToSettings:defaultSettings];
        }
    }
}

%end

%hook CKMessageEntryTextView

-(void)updateTextView {
    %orig;
    if (isDarkModeActive) {
        self.placeholderLabel.textColor = darkModeForegroundColour;
        self.textColor = darkModeBrightForegroundColour;
    }
    else if (isValidApplicationForDarkMode) {
        self.placeholderLabel.textColor = [UIColor lightGrayColor];
        self.textColor = [UIColor blackColor];
    }
}

%end

%hook UITableViewCellContentView

-(void)setBackgroundColor:(id)col {
    if (isDarkModeActive) {
        %orig([UIColor clearColor]);
    }
    else {
        %orig;
    }
}

%end

%hook MFRecipientTableViewCell

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        MSHookIvar<UIView*>(self, "_titleView").backgroundColor = [UIColor clearColor];
        MSHookIvar<UIView*>(self, "_detailView").backgroundColor = [UIColor clearColor];
    }
}

%end

%hook UIStatusBar

-(void)layoutSubviews {
    %orig;
    currentStatusBar = self;
    if (isDarkModeActive) {
        [self setForegroundColor:darkModeBrightForegroundColour];
    }
}

%end

%hook UICollectionView

-(void)setBackgroundColor:(id)arg1 {
    if (isDarkModeActive && [self isKindOfClass:%c(PUCollectionView)]) {
        %orig(darkModeBackgroundColour);
    }
    else {
        %orig;
    }
}

%end

%hook ABStyleProvider

-(id)membersBackgroundColor {
    if (isDarkModeActive) {
        return darkModeBackgroundColour;
    }
    else {
        return %orig;
    }
}

-(id) memberNameTextColor {
    if (isDarkModeActive) {
        return darkModeBrightForegroundColour;
    }
    else {
        return %orig;
    }
}

-(id) memberNameMeCardTextColor {
    if (isDarkModeActive) {
        return darkModeForegroundColour;
    }
    else {
        return %orig;
    }
}

-(id) membersHeaderContentViewBackgroundColor {
    if (isDarkModeActive) {
        return darkModeForegroundColour;
    }
    else {
        return %orig;
    }
}

%end

%hook _MFMailRecipientTextField

- (void)setTextColor:(id)col {
    if (isDarkModeActive && ! [self.superview isKindOfClass:%c(CKComposeRecipientView)]) {
        %orig(darkModeBrightForegroundColour);
    }
    else {
        %orig;
    }
}

%end

%hook CKUIBehavior

- (UIColor*)detailsBackgroundColor {
    if (isDarkModeActive) {
        return darkModeBackgroundColour;
    }
    else {
        return %orig;
    }
}

-(UIColor*) entryFieldButtonColor  {
    if (isDarkModeActive) {
        return darkModeForegroundColour;
    }
    else {
        return %orig;
    }
}

%end

%hook CKComposeRecipientContainerView

- (void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        NSInteger darkModeType = intForPermaKey(@"DarkMode");
        if (darkModeType == 2) {
            _UIBackdropViewSettings* settings = [_UIBackdropViewSettings settingsForStyle:0];
            [self.backdropView transitionToSettings:settings];
            [self.backdropView transitionToColor:[darkModeBackgroundColour colorWithAlphaComponent:0.7]];
        }
        else {
            [self.backdropView transitionToSettings:[_UIBackdropViewSettings settingsForStyle:1]];
        }
    }
    else {
        [self.backdropView transitionToStyle:0];
    }
}

%end

%hook CKComposeRecipientView

- (void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        self.labelView.textColor = darkModeForegroundColour;
    }
}

-(UITextView*) textView {
    if (isDarkModeActive) {
        %orig.textColor = darkModeBrightForegroundColour;
    }
    return %orig;
}

%end

%hook CKTranscriptRecipientsHeaderFooterView

-(void)layoutSubviews {
    %orig;
    if (isDarkModeActive) {
        self.headerLabel.textColor = darkModeForegroundColour;
        self.preceedingSectionFooterLabel.textColor = darkModeForegroundColour;
    }
}

-(void) setBottomSeparator:(UIView*)arg1 {
    if (isDarkModeActive) {
        arg1.backgroundColor = darkModeForegroundColour;
    }
    %orig;
}

-(void) setTopSeparator:(UIView*)arg1 {
    if (isDarkModeActive) {
        arg1.backgroundColor = darkModeForegroundColour;
    }
    %orig;
}

%end

%hook CKTranscriptDrawerContactsTableView

-(void)setSeparatorView:(UIView*)arg1 {
    if (isDarkModeActive) {
        arg1.backgroundColor = darkModeForegroundColour;
    }
    %orig;
}

%end

%hook ABLabeledCell

-(UIImageView*)chevron {
    UIImageView* iv = %orig;
    if (isDarkModeActive) {
        iv.image = [iv.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return iv;
}

%end

%hook CKPhotoPickerController

-(UITableViewCell*)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2 {
    UITableViewCell* o = %orig;
    if (isDarkModeActive) {
        o.tintColor = [[%c(CKUIBehavior) sharedBehaviors] appTintColor];
    }
    return o;
}

%end

%hook UITableViewLabel

-(void)setTextColor:(id)col {
    if (isDarkModeActive && [col isEqual:UIColorFromHexString(@"#007AFF")]) {
        UIColor* c = [[%c(CKUIBehavior) sharedBehaviors] appTintColor];
        %orig(c);
    }
    else {
        %orig;
    }
}

%end

%hook CKPhotoPickerCollectionViewController

-(void)loadView {
    %orig;
    if (isDarkModeActive) {
        ((UIViewController*)self).view.backgroundColor = darkModeBackgroundColour;
    }
}

%end
/*
   %hook PUPhotosSectionHeaderContentView // TODO FIX

   -(void)layoutSubviews {
    %orig;
    ((UIView*)self).backgroundColor = [UIColor redColor];
   }

   %end
 */

%hook CNAvatarCardHeaderView

-(void)setBackgroundColor:(id)col {
    if (isDarkModeActive)
        %orig(darkModeBackgroundColour);
    else
        %orig;
}

%end

%hook CNAvatarCardHighlightView

- (void)setHighlightColor:(id)arg1 {
    if(isDarkModeActive) {
        UIColor* col = darkModeBackgroundColour;
        if (isColourDark(col)) {
            col = brightnessAlteredColour(col, 1.1);
        }
        else {
            col = brightnessAlteredColour(col, 0.8);
        }
        %orig(col);
    }
    else
        %orig;
}

%end

%hook CNAvatarCardActionCell

- (void)_updateHighlightAnimated:(BOOL)arg1 {
    %orig;
    self.actionImageView.alpha = 1;
}

- (UIImageView*)actionImageView {
    if(isDarkModeActive) {
        %orig.tintColor = darkModeBrightForegroundColour;
        [%orig _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
    }
    return %orig;
}
- (UILabel*)moreLabel {
    if(isDarkModeActive) {
        %orig.textColor = darkModeForegroundColour;
        [%orig _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
    }
    return %orig;
}
- (UILabel*)titleLabel {
    if(isDarkModeActive) {
        %orig.textColor = darkModeBrightForegroundColour;
        [%orig _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
    }
    return %orig;
}
- (UILabel*)subtitleLabel {
    if(isDarkModeActive) {
        %orig.textColor = darkModeForegroundColour;
        [%orig _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
    }
    return %orig;
}

%end

%end // DARKMODE

%ctor {
    updatePrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR("me.chewitt.mcproprefs.settingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    defaultThemeInfo = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Default/Theme.plist", themesBaseDirectory]];

    BOOL enabled = ! boolForPermaKey(@"Enabled");

    if (enabled && ! [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobilemail"] && ! [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.MailCompositionService"] && ! [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.saurik.Cydia"]) {
        %init;

        if (! boolForPermaKey(@"EclipseSupport")) {
            %init(DARKMODE);
        }
    }
}

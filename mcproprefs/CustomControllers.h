#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

@interface CHMCPPSListController:PSListController
@end

@interface CHMCPPSListItemsController:PSListItemsController
@end

@interface CHMCPPSEditableListController:PSEditableListController
@end

@interface MCProPrefsListController:CHMCPPSListController <MFMailComposeViewControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
    NSMutableArray* themeListMinusDefault;
}
-(void) checkForPermaPlist;
@end

@interface CHMCThemeMakerController:CHMCPPSListController <UIAlertViewDelegate, UITextFieldDelegate> {
    NSString* themeName;
    NSString* pathToTheme;
}
@end

@interface CHMCNewThemeController:CHMCThemeMakerController {
    BOOL preLoaded;
}
@end

@interface CHMCEditThemeController:CHMCThemeMakerController
@end

@interface CHMCConvosThemesController:CHMCPPSListController  <UIAlertViewDelegate> {
    NSString* fallbackTheme;
}
@end

@interface CHMCBubbleController:CHMCPPSListController {
    NSString* plistName;
}
+(NSArray*) currentColours;
+(UIColor*) currentTextColour;
@end

@interface CHMCContactBubbleColourController:CHMCBubbleController
+(NSArray*) currentColoursForContact:(NSString*)contact;
+(UIColor*) currentTextColourForContact:(NSString*)contact;
@end

@interface CHMCContactsThemesController:CHMCPPSListController  <UIAlertViewDelegate>
@end

@interface CHMCThemeSelectionController:CHMCPPSEditableListController
@end

@interface CHMCConvoSpecificThemeSelectionController:CHMCPPSListController
@end

@interface CHMCSMSBubbleContoller:CHMCBubbleController
@end

@interface CHMCIMBubbleContoller:CHMCBubbleController
@end

@interface CHMCOtherBubbleContoller:CHMCBubbleController
@end

@interface CHMCBackgroundController:CHMCPPSListController <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    UIImage* unblurredBGImage;
    UIImage* blurredBGImage;
    CGFloat blurRadius;
}
-(void) updateOverlayColour;
-(void) loadImageForPreview;
+(BOOL) isColours;
@end

@interface CHMCColourPickerController:CHMCPPSListController {
    NSString* alphaKeyName;
    NSString* colourKeyName;
    NSString* plistPath;
    HRColorPickerView* colorPickerView;
}
@end

@interface CHMCChatViewController:CHMCPPSListController
@end

@interface CHMCChatViewPermaController:CHMCPPSListController
@end

@interface CHMCConvoListController:CHMCPPSListController
@end

@interface CHMCOtherPrefsController:CHMCPPSListController
@end

@interface CHMCInfoController:CHMCPPSListController
@end

@interface CHMCBetaController:CHMCPPSListController
@end

@interface CHMCTimeRangeEntryController:CHMCPPSListController
{
    UIDatePicker* datePicker;
}
@end

@interface CHMCCompatPrefsController:CHMCPPSListController
@end

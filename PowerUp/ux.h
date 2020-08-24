#import <UIKit/UIKit.h>
#import "global.h"

@interface ux : NSObject {
    @public
    UIWindow *__strong welcomeWindow;
    UIButton *__strong introNextButton;
    UIView *__strong currentIntroStepView;
    UIView *__strong welcomeView;
    UILabel *__strong percentageLabel;
    int intro_current_step;
    int intro_set_percentage;
    UIView *confirmAlertView;
    UIView *dateView;
    UIView *oledView; 
    UIView *curtainView;
    UIWindow *__strong curtainWindow;
    UIWindow *__strong confirmWindow;
    UIView *__strong backgroundView;
    UIView *__strong SBDateViewRef;
    UIView *__strong SBDateViewParentRef;
    UIWindow *__strong oledWindow;
    UIView *__strong slidingView;       // For displaying battery perc in OLED mode
    UIView *__strong slidingView2;      // For displaying battery perc in OLED mode
    UILabel *__strong batteryPercLabel; // For displaying battery perc in OLED mode
    UIImageView *__strong o_boltView;   // For displaying battery perc in OLED mode
    UIImageView *__strong o_boltView2;  // For displaying battery perc in OLED mode
    UIView *__strong underlineView;     // For displaying hold lock animation in OLED mode
    UIView *__strong underlineSlideView;// For displaying hold lock animation in OLED mode
}
+(instancetype)sharedInstance;
+ (UIImage *)imageWithColor:(UIColor *)color;
-(void)confirmAlert;
-(void)hideOLED;
-(void)hideCurtain;
-(void)showCurtain;
-(void)hide_confirmAlert:(UIButton *)sender;
-(void)setSBDateViewRef:(UIView *)ref;
-(void)showOLEDwithPerc:(int)perc;
-(void)updateOLEDBattery:(int)perc;
@end

@interface UIWindow (tweaked)
-(void)_setSecure:(BOOL)arg;
@end



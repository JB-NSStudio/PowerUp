#import "ux.h"
#include <objc/runtime.h>

#define CONFIRM_BUTTON_TAG 447 // anything non-zero
#define INTRO_TEXT @"Thanks for downloading PowerUp. As this is your first run, we will start by configuring some important settings. This won't take long but if you wish to exit this setup process, press the home button at any time. All settings can be configured later in your settings application."
#define INTRO_PERCENTAGE_TEXT @"Select the battery percentage you would like the tweak enabled at. When above this percentage, PowerUp will disable, waking your device and you will not be prompted to enter PowerUp mode when plugged in."
#define HEIGHT [[UIScreen mainScreen] bounds].size.height
#define WIDTH [[UIScreen mainScreen] bounds].size.width
#define WIDTH97 WIDTH * 0.97101449275
#define HEIGHT97 HEIGHT * 0.97101449275


@implementation ux

// Helper to apply colour to image
+ (UIImage *)imageWithColor:(UIColor *)color {
   CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
   UIGraphicsBeginImageContext(rect.size);
   CGContextRef context = UIGraphicsGetCurrentContext();

   CGContextSetFillColorWithColor(context, [color CGColor]);
   CGContextFillRect(context, rect);

   UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();

   return image;
}

// Called by notification listener
void startWakeButton() {
    [[ux sharedInstance] holdLockAnimation:YES];
}
void stopWakeButton() {
    [[ux sharedInstance] holdLockAnimation:NO];
}

-(void)proxy_Hide{[[ux sharedInstance] hide_confirmAlert:nil];}

+(instancetype)sharedInstance {
    static ux *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ux alloc] init];
        LISTEN_NOTIF(startWakeButton, "com.kurrtandsquiddy.powerup.oled.startWakeButton")
        LISTEN_NOTIF(stopWakeButton, "com.kurrtandsquiddy.powerup.oled.stopWakeButton")
    });
    return sharedInstance;
}


// show Confirm alert
-(void)confirmAlert{
    if(confirmWindow) return;
    dispatch_async (dispatch_get_main_queue(), ^{
         confirmWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
         confirmWindow.windowLevel = DBL_MAX;
         if ([confirmWindow respondsToSelector:@selector(_setSecure:)])
             [confirmWindow _setSecure:YES]; //makes it displayable in the lockscreen by first testing if the current iOS responds to the _setSecure method.
        
        UIViewController *controller = [[UIViewController alloc] init];
        confirmWindow.rootViewController = controller;
        // create the alert
        //This detects whether the phone is horizontal or vertical and adjusts the display
        if(HEIGHT > WIDTH){
            confirmAlertView = [[UIView alloc] initWithFrame:CGRectMake((WIDTH - WIDTH97) / 2 , HEIGHT, WIDTH97, 300.f)];
        }else {
            confirmAlertView = [[UIView alloc] initWithFrame:CGRectMake((WIDTH - HEIGHT97) / 2 , HEIGHT, HEIGHT97, 300.f)];
        }
        confirmAlertView.backgroundColor = [UIColor whiteColor];

        //curvy time
        UIBezierPath *cornersPath = [UIBezierPath bezierPathWithRoundedRect:confirmAlertView.bounds  byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight|UIRectCornerBottomRight|UIRectCornerBottomLeft) cornerRadii:CGSizeMake(40, 40)];
		CAShapeLayer *maskLayer = [CAShapeLayer layer];
		maskLayer.path = cornersPath.CGPath;
        confirmAlertView.layer.mask = maskLayer;

        //create big button
         UIButton *confirmButton =[[UIButton alloc] initWithFrame:CGRectMake((confirmAlertView.frame.size.width / 3) - 105 , 210, 150, 60)];
        [confirmButton setBackgroundImage:[ux imageWithColor:[UIColor colorWithRed:0 green:.411 blue:1 alpha:1]] forState:UIControlStateHighlighted];
        [confirmButton setBackgroundImage:[ux imageWithColor:[UIColor colorWithRed:0 green:.49 blue:1 alpha:1]] forState:UIControlStateNormal];
        [confirmButton addTarget:self action:@selector(hide_confirmAlert:) forControlEvents:UIControlEventTouchUpInside];
        confirmButton.adjustsImageWhenHighlighted = YES;
        confirmButton.layer.cornerRadius = 16;
        confirmButton.tag = CONFIRM_BUTTON_TAG;

        //create other button
       UIButton *disableButton =[[UIButton alloc] initWithFrame:CGRectMake(((confirmAlertView.frame.size.width / 3)*2) - 55 , 210, 150, 60)];
        [disableButton setBackgroundImage:[ux imageWithColor:[UIColor colorWithRed:0.55 green:0.55 blue:.56 alpha:1]] forState:UIControlStateHighlighted];
        [disableButton setBackgroundImage:[ux imageWithColor:[UIColor colorWithRed:.68 green:.68 blue:.69 alpha:1]] forState:UIControlStateNormal];
        [disableButton addTarget:self action:@selector(hide_confirmAlert:) forControlEvents:UIControlEventTouchUpInside];
        disableButton.adjustsImageWhenHighlighted = YES;
        disableButton.layer.cornerRadius = 16;

        //Label Button
        UILabel *button1Label = [[UILabel alloc] initWithFrame:confirmButton.bounds];
        button1Label.text = @"Confirm";
        button1Label.textColor = [UIColor whiteColor];
        button1Label.textAlignment = 1;
        button1Label.font = [UIFont boldSystemFontOfSize:25];


         //Label Button
        UILabel *button2Label = [[UILabel alloc] initWithFrame:disableButton.bounds];
        button2Label.text = @"Ignore";
        button2Label.textColor = [UIColor whiteColor];
        button2Label.textAlignment = 1;
        button2Label.font = [UIFont boldSystemFontOfSize:25];

        //curvy time (Rounds Corners)
        UIBezierPath *buttonCorners = [UIBezierPath bezierPathWithRoundedRect:confirmButton.bounds  byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight|UIRectCornerBottomRight|UIRectCornerBottomLeft) cornerRadii:CGSizeMake(12, 12)];
		CAShapeLayer *buttonMaskLayer = [CAShapeLayer layer];
		buttonMaskLayer.path = buttonCorners.CGPath;
        confirmButton.layer.mask = buttonMaskLayer;
        
        //curvy time (Rounds Corners)
        UIBezierPath *disableButtonCorners = [UIBezierPath bezierPathWithRoundedRect:disableButton.bounds  byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight|UIRectCornerBottomRight|UIRectCornerBottomLeft) cornerRadii:CGSizeMake(12, 12)];
		CAShapeLayer *disableButtonMaskLayer = [CAShapeLayer layer];
		disableButtonMaskLayer.path = disableButtonCorners.CGPath;
        disableButton.layer.mask = disableButtonMaskLayer;

        //Title
        UILabel *powerUP = [[UILabel alloc] initWithFrame:CGRectMake(7.f, 5.f, 220.f ,70.f)];
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"PowerUp"];
        [text addAttribute:NSKernAttributeName value:@1.5 range:NSMakeRange(0, text.length)];
        [powerUP setAttributedText:text];
        powerUP.textColor = [UIColor darkTextColor];
        powerUP.textAlignment = 1;        
        powerUP.font = [UIFont boldSystemFontOfSize:40];

        //Body Text
        UILabel *mainText = [[UILabel alloc] initWithFrame:CGRectMake(29.f,50.f,350.f,160.f)];
        mainText.text = @"Would you like to enable PowerUp? \nThis will put your device in a hibernation mode and you will have to unplug or override to resume using your device";
        mainText.textAlignment = 0;
        mainText.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        mainText.textColor = [UIColor darkTextColor];
        [mainText setNumberOfLines:4];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:mainText.text];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:5];
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, mainText.text.length)];
        mainText.attributedText = attributedString;

        //Image
        UIImage *bolt = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/PowerUp.bundle/bolt@2x.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *boltView =[[UIImageView alloc] initWithImage:bolt];
        boltView.frame = CGRectMake(215.f, 20.f, 30.f, 42.f);


        //Blur Background
        backgroundView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        backgroundView.backgroundColor = [UIColor colorWithRed:0.1 green:.1 blue:.1 alpha:1];
        UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(proxy_Hide)];
        [backgroundView addGestureRecognizer:singleFingerTap];
        backgroundView.alpha = 0.0;

        // Add subviews
        [disableButton addSubview:button2Label];
        [confirmButton addSubview:button1Label];
        [confirmAlertView addSubview:boltView];
        [confirmAlertView addSubview: confirmButton];
        [confirmAlertView addSubview: disableButton];
        [confirmAlertView addSubview: powerUP];
        [confirmAlertView addSubview: mainText];

        [controller.view addSubview: backgroundView];
        [controller.view addSubview: confirmAlertView];
        

        [confirmWindow setHidden:NO];
        [confirmWindow makeKeyAndVisible];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
 		    HBLogDebug(@"Height: %f Width: %f", HEIGHT, WIDTH);
 	    });
       
        [UIView animateWithDuration:0.2 animations:^{
            if(HEIGHT > WIDTH){
                confirmAlertView.frame = CGRectMake((WIDTH - WIDTH97) / 2 , HEIGHT - 306.f, WIDTH97, 300.f);
            }else {
                confirmAlertView.frame = CGRectMake((WIDTH - HEIGHT97) / 2 , HEIGHT - 306.f, HEIGHT97, 300.f);
            }

            backgroundView.alpha = 0.2;
        }];
    });
}

// hide confirm alert
-(void)hide_confirmAlert:(UIButton *)sender {
    BOOL state_confirmed = (sender && sender.tag == CONFIRM_BUTTON_TAG);
    if (confirmWindow && confirmAlertView) dispatch_async (dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.2 animations:^{
            confirmAlertView.frame = CGRectMake(6.f, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width-12.f, 300.f);
             backgroundView.alpha = 0.0;
        } completion:^(BOOL finished) {
            confirmWindow.hidden = YES;
            if (state_confirmed) POST_NOTIF(ENABLE_NOTIF)
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            confirmWindow = nil;
        });
    });
}

// OLED
-(void)showOLEDwithPerc:(int)perc {
    dispatch_async (dispatch_get_main_queue(), ^{
        // Create the window and its root view controller
        oledWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        oledWindow.windowLevel = DBL_MAX;
        if ([oledWindow respondsToSelector:@selector(_setSecure:)])
            [oledWindow _setSecure:YES]; //makes it displayable in the lockscreen by first testing if the current iOS responds to the _setSecure method.
        UIViewController *controller = [[UIViewController alloc] init];
        oledWindow.rootViewController = controller;
        oledView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        oledView.alpha = 1.f;
        oledView.backgroundColor = [UIColor blackColor];
        [controller.view addSubview: oledView];
        
        // Bolt and Battery Percentage
        UIView *boltNester = [[UIView alloc] initWithFrame:CGRectZero];
        boltNester.clipsToBounds = YES;

        // Outline Bolt Image
        UIImage *bolt = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/PowerUp.bundle/bolt.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        o_boltView =[[UIImageView alloc] initWithImage:bolt];
        o_boltView.frame = CGRectMake(0.f, 0.f, 40.f, 56.f);
        o_boltView.tintColor = [UIColor whiteColor];

        // Battery Percentage Label
        batteryPercLabel = [[UILabel alloc] initWithFrame: CGRectMake(0.f, o_boltView.frame.origin.y + o_boltView.frame.size.height + 10.f, [[UIScreen mainScreen] bounds].size.width, 100.f)];
        batteryPercLabel.font = [UIFont systemFontOfSize:20];
        batteryPercLabel.textColor = [UIColor whiteColor];
        [batteryPercLabel setText: [NSString stringWithFormat:@"%d%%", (int)(perc+0.5f)]];
        batteryPercLabel.textAlignment = NSTextAlignmentCenter;
        [batteryPercLabel sizeToFit];

        // Solid Inner Bold Image
        UIImage *bolt2 = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/PowerUp.bundle/bolt_fill.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        o_boltView2 =[[UIImageView alloc] initWithImage:bolt2];
        o_boltView2.frame = CGRectMake(0.f, 0.f, o_boltView.frame.size.width-2.f, o_boltView.frame.size.height-3.f);
        o_boltView2.tintColor = [UIColor colorWithRed:0 green:.411 blue:1 alpha:1];

        // Sliding View to Reveal The Innner Bolt
        slidingView = [[UIView alloc] initWithFrame:o_boltView2.frame];
        slidingView.backgroundColor = [UIColor blackColor];

        // Sliding View to Reveal The Outer Bolt
        slidingView2 = [[UIView alloc] initWithFrame:o_boltView.frame];
        slidingView2.backgroundColor = [UIColor blackColor];
        slidingView2.alpha = 0.7f;

        // Wake Label And Animation Bar
        UIView *detailNester = [[UIView alloc] initWithFrame:CGRectZero];
        detailNester.clipsToBounds = YES;

        // Wake Label
        UILabel *wakeLabel = [[UILabel alloc] initWithFrame: CGRectMake(0.f, 0.f, [[UIScreen mainScreen] bounds].size.width, 100.f)];
        wakeLabel.font = [UIFont systemFontOfSize:15];
        wakeLabel.textColor = [UIColor whiteColor];
        [wakeLabel setText: @"Hold lock for 2 seconds to wake"];
        wakeLabel.textAlignment = NSTextAlignmentCenter;
        [wakeLabel sizeToFit];

        // Underline View
        underlineView = [[UIView alloc] initWithFrame:CGRectMake(wakeLabel.frame.origin.x, wakeLabel.frame.origin.y + wakeLabel.frame.size.height + 6.f, wakeLabel.frame.size.width, 2.f)];
        underlineView.backgroundColor = [UIColor whiteColor];
        underlineView.layer.cornerRadius = 1.f;
        underlineView.layer.masksToBounds = true;

        // Underline Slide View to Animate Bar
        underlineSlideView = [[UIView alloc] initWithFrame: underlineView.frame];
        underlineSlideView.backgroundColor = [UIColor blackColor];

        // Adjust frames
        // Bolt Container
        boltNester.frame = CGRectMake(
            0, 
            0, 
            (batteryPercLabel.frame.size.width+12.f>o_boltView.frame.size.width)?batteryPercLabel.frame.size.width+12.f:o_boltView.frame.size.width,
            batteryPercLabel.frame.origin.y + batteryPercLabel.frame.size.height
        );
        batteryPercLabel.frame = CGRectMake(
            0,
            batteryPercLabel.frame.origin.y,
            boltNester.frame.size.width,
            batteryPercLabel.frame.size.height
        );
        boltNester.center = CGPointMake(
            oledView.center.x, 
            oledView.frame.size.height - boltNester.frame.size.height/2.f - 35.f
        );
        o_boltView.center = CGPointMake(boltNester.frame.size.width/2.f, o_boltView.frame.size.height/2.f);
        o_boltView2.center = o_boltView.center;
        // Detail Container
        detailNester.frame = CGRectMake(
            0,
            0,
            wakeLabel.frame.size.width,
            underlineView.frame.origin.y + underlineView.frame.size.height
        );
        detailNester.center = oledView.center;

        // Move sliding views to display percentage
        slidingView.center = CGPointMake(o_boltView2.center.x, o_boltView2.center.y - o_boltView2.frame.size.height * (perc/100.f));
        slidingView2.center = CGPointMake(o_boltView.center.x, o_boltView.center.y - o_boltView.frame.size.height * (perc/100.f));

        // Add views to containers
        // Bolt Container
        [boltNester addSubview:o_boltView];
        [boltNester insertSubview:o_boltView2 belowSubview:o_boltView];
        [boltNester insertSubview:slidingView belowSubview:o_boltView];
        [boltNester addSubview:batteryPercLabel];
        [boltNester addSubview:slidingView2];
        // Detail Container
        [detailNester addSubview: wakeLabel];
        [detailNester addSubview:underlineView];
        [detailNester addSubview:underlineSlideView];

        // Show nested views
        [oledView addSubview: boltNester];
        [oledView addSubview: detailNester];

        if (SBDateViewRef) {
            // Steal the clock
            SBDateViewParentRef = SBDateViewRef.superview;
            [oledView addSubview:SBDateViewRef];
        }

        // Show it!
        [oledWindow setHidden:NO];
        [oledWindow makeKeyAndVisible];
    });
}

// Curtain to act as a failsafe if OLED isnt used. This should never be needed but helps avoid the screen
// turning on if the device temporarily exits sleep.
-(void)showCurtain{
    curtainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        curtainWindow.windowLevel = DBL_MAX;
        if ([curtainWindow respondsToSelector:@selector(_setSecure:)])
            [curtainWindow _setSecure:YES]; //makes it displayable in the lockscreen by first testing if the current iOS responds to the _setSecure method.
        UIViewController *controller = [[UIViewController alloc] init];
        curtainWindow.rootViewController = controller;
        curtainView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        curtainView.alpha = 0.f;
        curtainView.backgroundColor = [UIColor blackColor];
        [controller.view addSubview: curtainView];

        [curtainWindow setHidden:NO];
        [curtainWindow makeKeyAndVisible];

        [UIView animateWithDuration:1.f animations:^{
            curtainView.alpha = 1.f; 
    }];
}

// Remove the curtain
-(void)hideCurtain{
    [UIView animateWithDuration:0.5 animations:^{
            curtainView.alpha = 0.0;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
        [curtainWindow setHidden:YES];
    });
}

// Remove the OLED display
-(void)hideOLED {
    // Put the clock back where it came from
    if (SBDateViewParentRef) [SBDateViewParentRef addSubview:SBDateViewRef];
    [UIView animateWithDuration:0.5 animations:^{
            oledView.alpha = 0.0; 
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
        [oledWindow setHidden:YES];
    });
}

// Setter to store a reference of the SBDateView for use in OLED
-(void)setSBDateViewRef:(UIView *)ref {
    SBDateViewRef = ref;
}

// Updates the OLED views when battery percentage changes
-(void)updateOLEDBattery:(int)perc {
    dispatch_async (dispatch_get_main_queue(), ^{
        if (batteryPercLabel) [batteryPercLabel setText: [NSString stringWithFormat:@"%d%%", (int)(perc+0.5f)]];
        if (slidingView && o_boltView2)
            slidingView.center = CGPointMake(o_boltView2.center.x, o_boltView2.center.y - o_boltView2.frame.size.height * (perc/100.f));
        if (slidingView2 && o_boltView)
            slidingView2.center = CGPointMake(o_boltView.center.x, o_boltView.center.y - o_boltView.frame.size.height * (perc/100.f));
    });
}

// Apply animation when holding lock in OLED
-(void)holdLockAnimation:(BOOL)holding {
    if (holding) {
        [UIView animateWithDuration:WAKE_HOLD_POWER_SECS animations:^{
            underlineSlideView.center = CGPointMake(underlineView.center.x + underlineView.frame.size.width, underlineView.center.y);
        }];
    } else {
        [underlineSlideView.layer removeAllAnimations];
        underlineSlideView.center = underlineView.center;
    }
}

@end


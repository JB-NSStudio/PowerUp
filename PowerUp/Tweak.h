#import "ux.h"
#include <IOKit/hid/IOHIDEventQueue.h>
#import "global.h"
#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

// for testing
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/pwr_mgt/IOPM.h>
#import <IOKit/pwr_mgt/IOPMLibPrivate.h>
#import <IOKit/IOKitLib.h>
//

static void killBackgroundApps();



@interface BCBatteryDevice : NSObject
-(long long)percentCharge;
-(BOOL)isCharging;
-(BOOL)isPowerSource;
-(long long)productIdentifier;
-(NSString *)identifier;
-(NSString *)accessoryIdentifier;
-(NSString *)name;
-(BOOL)isConnected;
@end

@interface SBDisplayItem: NSObject
@property (nonatomic,copy,readonly) NSString * bundleIdentifier;
@end

@interface SBMainSwitcherViewController: UIViewController
+ (id)sharedInstance;
-(id)recentAppLayouts;
-(id)_currentAppLayout;
-(void)_addAppLayoutToFront:(id)arg1;
-(void)_deleteAppLayout:(id)arg1 forReason:(long long)arg2;
@end


@interface AVFlashlight : NSObject
-(BOOL)setFlashlightLevel:(float)arg1 withError:(id*)arg2;
-(void)turnPowerOff;
@end

@interface SBAppLayout:NSObject
@property (nonatomic,copy) NSDictionary * rolesToLayoutItemsMap;                                         //@synthesize rolesToLayoutItemsMap=_rolesToLayoutItemsMap - In the implementation block
@end

@interface SBFLockScreenDateView : UIView
@end

@interface SBFLockScreenDateViewController : UIViewController
-(void)_updateView;
@property (assign,nonatomic) BOOL screenOff;    
@end

@interface CSCoverSheetViewController : UIViewController
- (id)dateView;
@end

@interface SBAirplaneModeController : NSObject
+(id)sharedInstance;
-(BOOL)isInAirplaneMode;
-(void)setInAirplaneMode:(BOOL)arg1;
@end

@interface SBTelephonyManager : NSObject
+(id)sharedTelephonyManager;
-(BOOL)isInAirplaneMode;
-(void)setIsInAirplaneMode:(BOOL)arg1;
@end

@interface SBDashBoardIdleTimerProvider : NSObject
-(void)addDisabledIdleTimerAssertionReason:(id)arg1;
-(void)removeDisabledIdleTimerAssertionReason:(id)arg1;
@end

@interface SBDashBoardQuickActionsViewController
-(void)_toggleFlashlight;
-(BOOL)_isFlashlightOn;
@end

@interface SBDashBoardIdleTimerController : NSObject
-(void)addIdleTimerDisabledAssertionReason:(id)arg1;
-(void)removeIdleTimerDisabledAssertionReason:(id)arg1;
@end

@interface SBHomeGesturePanGestureRecognizer : NSObject
-(UIView *)viewForTouchHistory;
@end

@interface SBOrientationLockManager : NSObject
+(id)sharedInstance;
-(void)lock:(long long)arg1;
-(void)unlock;
-(long long)userLockOrientation;
-(BOOL)isUserLocked;
@end

@interface CommonProduct : NSObject 
- (void)putDeviceInThermalSimulationMode:(NSString *)simulationMode;
-(int)thermalState;
-(void)setThermalState:(int)arg1;
@end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
-(void)_wakeScreenForTapToWake;
@end

@interface _CDBatterySaver : NSObject
+ (id)batterySaver;
- (int)getPowerMode;
- (int)setMode:(int)arg1;
@end

@interface SBClockDataProvider : NSObject
-(void)_publishBulletinForNotification:(id)arg1;
@end




@interface SBUserAgent
-(void)lockAndDimDevice;
-(void)lockAndDimDeviceDisconnectingCallIfNecessary:(BOOL)arg1;
//-(void)setMinimumBacklightLevel:(float)arg1 animated:(BOOL)arg2;
@end


@interface SpringBoardClass
+(id)sharedApplication;
-(id)pluginUserAgent;
@end


@interface SpringBoard
- (id)_accessibilityFrontMostApplication;
-(void)setBatterySaverModeActive:(BOOL)arg1;
-(void)_simulateHomeButtonPress;
@end





@interface SBStatusBarManager : NSObject  {

	NSHashTable* _statusBars;
	UIWindow* _recycledStatusBarsContainerWindow;
	NSMutableArray* _recycledStatusBars;
	NSHashTable* _hideStatusBarAssertions;
}
@property (readonly) unsigned long long hash; 
@property (readonly) Class superclass; 
@property (copy,readonly) NSString * description; 
@property (copy,readonly) NSString * debugDescription; 
+(id)sharedInstance;
-(id)init;
-(NSString *)description;
-(NSString *)debugDescription;
-(id)succinctDescription;
-(id)descriptionWithMultilinePrefix:(id)arg1 ;
-(id)succinctDescriptionBuilder;
-(id)descriptionBuilderWithMultilinePrefix:(id)arg1 ;
-(void)handleStatusBarTapWithEvent:(id)arg1 ;
-(id)createStatusBarWithReason:(id)arg1 withFrame:(CGRect)arg2 ;
-(BOOL)isFrontMostStatusBarHidden;
-(id)frontMostStatusBarStyleRequest;
-(void)recycleStatusBar:(id)arg1 ;
-(id)createStatusBarWithReason:(id)arg1 ;
-(id)acquireHideFrontMostStatusBarAssertionForReason:(id)arg1 ;
-(id)trailingStatusBarStyleRequest;
-(void)_removeStatusBarContainer:(id)arg1 ;
@end

@interface SBUIBiometricResource
-(void)noteScreenDidTurnOff;
@end

@interface SBUIController : NSObject 
+(SBUIController *)sharedInstance;
-(int)batteryCapacityAsPercentage;
@end

@interface RPScreenRecorder
-(id)sharedRecorder;
-(BOOL)isRecording;
-(void)stopRecordingAndSaveToCameraRoll:(/*^block*/id)arg1;
@end


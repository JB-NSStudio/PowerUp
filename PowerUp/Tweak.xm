#import "Tweak.h"


//Trackers and Caches
static int 				cachedLPM = 0;
static long long 		userLockOrientation;
static id 				idleTimerController = nil;
static BOOL 			isUserLocked;
static BOOL 			cachedAirplane = NO;
static BOOL 			isEffectEnabled = NO;
static BOOL 			isPowerButtonDown = YES;

//Refs
static AVFlashlight 	*flashLightObj;
static CommonProduct 	*currentProduct;
static UIView 			*jellyFishUpperInfoView = nil;
static id 				dashboardButtonsVCInstance = nil;

//Worthless piece of shit
static NSTimer* 		holdTimer;

//Prefs
static int 	kAutoWakePercent = DEFAULT_AUTO_WAKE_PERC;
static BOOL kDeepsleep = YES;
static BOOL kAutoWake = YES;
static BOOL kThrottle = YES;
static BOOL kEnabled = YES;
static BOOL kDaemon = NO;
static BOOL kOLED = NO;
static int  kUnplugWakeDelay = 0;
static BOOL kRespringToWake = NO;

// tweak logging convenience method
static void tlog(NSString *msg) {
    HBLogDebug(@"["TWEAK_ABBR"] %@", msg);
}

//Fuction call to run RMP macro to start deepsleep
static void sleep_sys() {
	ROOT_ME_PLS(sleep)
}

//Function call to killall RMP to stop deepsleep loop
static void wake_sys() {
	KILL_RMP
}

#pragma mark - Ref Hooks
/* 
	All credit goes to Ryan Petrich for this
	Find his original source code here:	https://github.com/rpetrich/Powercuff/tree/master
	@rpetrich on Twitter
*/

/*
	This works by grabbing the only instance of CommonProduct and keeping a ref to it.
	When we enable the effect, we'll call putDeviceInThermalSimulationMode to convince it to
	"thermal throttle" the device. 
*/
%group thermalmonitord
	%hook CommonProduct
		- (id)initProduct:(id)data{
			if ((self = %orig())) 
				if ([self respondsToSelector:@selector(putDeviceInThermalSimulationMode:)]) 
					currentProduct = self;
			return self;
		}

		- (void)dealloc{
			if (currentProduct == self) currentProduct = nil;
				%orig();
		}

	%end //CommonProduct
%end //group(thermalmonitord)


// %hook SpringBoard
// 	-(void)_ringerChanged:(struct __IOHIDEvent *)arg1 {
// 		killBackgroundApps();
// 		%orig;
// 	}
// %end


%hook SBFLockScreenDateView
	//Grab a reference to dateView so we can add it to OLED mode if necessary
	-(void)layoutSubviews {
		%orig;
		[[ux sharedInstance] setSBDateViewRef: self];
	}


	// Stop clock hiding in oled when normally showing charge info
	-(void)setContentAlpha:(double)arg1 withSubtitleVisible:(BOOL)arg2 {
		if (isEffectEnabled && kOLED) %orig(1.0, YES);
		else %orig;
	}
%end //SBFLockScreenDateView


%hook CSCoverSheetViewController
//This hides weather and the lock glyph for Jellyfish
//Feel free to make a PR to add support to other tweaks but this if one tweak both of us had.
	-(void)viewDidLoad {
		%orig();
		for (id vw in [[self dateView] subviews])
			//Loop through the class names
			if ([NSStringFromClass([vw class]) isEqualToString:@"JFUpperInformationView"]) {
				//cache the ref to enable later when we put the time back.
				jellyFishUpperInfoView = vw;
				if (isEffectEnabled) [jellyFishUpperInfoView setHidden:YES];
				break;
			}
	}
%end //CSCoverSheetViewController


//Grab a reference of QA buttons to toggle flashlight if its on when enable_proccess is called
%hook SBDashBoardQuickActionsViewController
	-(void)loadView {
		dashboardButtonsVCInstance = self;
		%orig;
	}
%end //SBDashBoardQuickActionsViewController


//Get a copy of another source of flashlight to try and dismiss if needed
%hook AVFlashlight
	-(id)init {
		flashLightObj = %orig;
		return flashLightObj;
	}
%end //AVFlashlight

#pragma mark - Charge Logic


%hook BCBatteryDevice
	-(void)setCharging:(BOOL)arg1 {
		//Check to see if we're a power source.
		//This function also gets called when interacting with airpods but this flag is false.
		if ([self isPowerSource]) {
			//Are we just now chargine, below the AutoWakePercent and not already enabled?
			if (arg1 && ![self isCharging] && [self percentCharge] <= kAutoWakePercent && !isEffectEnabled) {
				//If we're globally enabled show the confirmation alert
				if(kEnabled) [[ux sharedInstance] confirmAlert];
			}

			//Did we just disconnect and are currently enabled? 
			else if (!arg1 && [self isCharging] && isEffectEnabled) {
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kUnplugWakeDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
						/*If device is plugged into a low voltage source or power surges for whatever reason
						dont disable the effect.*/
						if (![self isCharging]) {
							// Disable the effect
							POST_NOTIF(DISABLE_NOTIF)
						}
					});
				
			}
			//Did we unplug and effect isnt enabled?
			else if (!arg1 && [self isCharging] && !isEffectEnabled) {
				//Dissmiss confirmation dialogue
				[[ux sharedInstance] hide_confirmAlert:nil];
			}
		}
		%orig;
	}


	//Hook setPercentCharge method to disable if above kAutoWakePercent
	//This is lightweight and does not require any timers
	-(void)setPercentCharge:(long long)arg1 {
		%orig;
		if (isEffectEnabled) {
			//If OLED is enabled, update the display
			if (kOLED) [[ux sharedInstance] updateOLEDBattery:(int)arg1];
			//If we need to wake up, post DISABLE
			if (kAutoWake && arg1 > kAutoWakePercent) POST_NOTIF(DISABLE_NOTIF)
		}
	}
%end //BCBatteryDevice

#pragma mark - Screen Effect


//Stop local notifications from waking the screen such as a game prompt.
%hook SBClockDataProvider
	-(void)_publishBulletinForNotification:(id)arg1 {
		if (!isEffectEnabled) {
			%orig;
		}
	}
%end

%hook SBUIBiometricResource
	//If the screen tries to turn on, no it didnt
	-(void)noteScreenWillTurnOn {
		if (isEffectEnabled) [self noteScreenDidTurnOff];
		 else %orig;
	}
%end //SBUIBiometricResource


%hook SBLockScreenViewControllerBase
	//If the screen tries to turn on, no it didnt
	-(void)setInScreenOffMode:(BOOL)arg1 forAutoUnlock:(BOOL)arg2 {
		if (isEffectEnabled && !kOLED) %orig(YES, arg2);
		else %orig;
	}

	//If the screen tries to turn on, no it didnt
	-(void)setInScreenOffMode:(BOOL)arg1 {
		if (isEffectEnabled && !kOLED) %orig(YES); 
		else %orig;
	}
%end //SBLockScreenViewControllerBase


%hook SBLiftToWakeController
	//If the screen tries to turn on, no it didnt
	-(void)wakeGestureManager:(id)arg1 didUpdateWakeGesture:(long long)arg2 {
		if (!isEffectEnabled) %orig;
	}
%end //SBLiftToWakeController





#pragma mark - Static Functions

/*
	This is all fairly self explanatory.
	Functions are to keep enable_process_jobs as clean as possible
*/
static void enableAirplaneMode(){
	SBAirplaneModeController *airplaneManager = [%c(SBAirplaneModeController) sharedInstance];
	cachedAirplane = [airplaneManager isInAirplaneMode];														
    [airplaneManager setInAirplaneMode:YES];
	
}

static void returnAirplaneMode(){
	SBAirplaneModeController *airplaneManager = [%c(SBAirplaneModeController) sharedInstance];
	if (cachedAirplane){																																
		[airplaneManager setInAirplaneMode:YES];
	} else{															
        [airplaneManager setInAirplaneMode:NO];
	}
}

//There are more keys than this in PowerCuff see thermalmonitord Group
static void lpm_throttle() {
    if (currentProduct) {
        [currentProduct putDeviceInThermalSimulationMode: @"heavy"];
	}
}

static void lpm_dethrottle() {
    if (currentProduct) 
        [currentProduct putDeviceInThermalSimulationMode: @"off"];
}

static void enableLPM(){
	[[%c(_CDBatterySaver) batterySaver] setMode:1];
    [[%c(SpringBoard) sharedApplication] setBatterySaverModeActive:YES];
}

static void returnLPM(){
	if(!cachedLPM){
	[[%c(_CDBatterySaver) batterySaver] setMode:0];
	[[%c(SpringBoard) sharedApplication] setBatterySaverModeActive:NO];
	}
}

static void wakeScreen(){
	[[%c(SBLockScreenManager) sharedInstance] _wakeScreenForTapToWake];
}

static void killBackgroundApps(){
	//Run RMP killapps
		ROOT_ME_PLS(killapps)
		//This code is from a failed attempt to kill apps from switcher, ill come back to this when i finish a tool to fix a bug in this.
			// SBMainSwitcherViewController *appSwitcher = [%c(SBMainSwitcherViewController) sharedInstance];
			// NSArray *apps = appSwitcher.recentAppLayouts;
			// id one = @1;
			// for(SBAppLayout * app in apps) {
			// 	SBDisplayItem *item = [app.rolesToLayoutItemsMap objectForKey:one];
			// if(app == [appSwitcher _currentAppLayout]){
 
			//Declare for posix_spawn
			// pid_t pid; 
			// //get the current bundleIdentifier as C String
			// SBDisplayItem *item = [app.rolesToLayoutItemsMap objectForKey:one];
			// NSString *bundleID = item.bundleIdentifier;
			// NSString *cExecPath = [[NSBundle bundleWithIdentifier:bundleID] executablePath];
			// //Nuke it and wait for it to finish.
			// HBLogDebug(@"[PUP] Path %@, Current app:%@", cExecPath, [appSwitcher _currentAppLayout]);
			// const char* args[] = {"/usr/bin/killall", "-9", cExecPath, NULL};
			// posix_spawn(&pid, args[0], NULL, NULL, (char* const*)args, NULL);
	
			// }else {
			// 	[appSwitcher _addAppLayoutToFront:app];
			// 	[appSwitcher _deleteAppLayout:app forReason: 1];
			// }


			   
	}
	
	
				

    

/*	SBDisplayItem *item = [app.rolesToLayoutItemsMap objectForKey:one];
			NSString *bundleID = item.bundleIdentifier;
			const char *cExecPath = [[[NSBundle bundleWithIdentifier:bundleID] executablePath] UTF8String];
			HBLogDebug(@"[PUP] Path %s", cExecPath);*/


void externalTweakSupport() {
	if ([[[NSProcessInfo processInfo].processName uppercaseString] isEqualToString:@"SPRINGBOARD"]) {
		// JellyFish
		if (jellyFishUpperInfoView) [jellyFishUpperInfoView setHidden: isEffectEnabled];
	}
}

void lockAndDimDevice() {
	[[[%c(SpringBoard) sharedApplication] pluginUserAgent] lockAndDimDevice]; 
	
}

void turnOffFlash(){
    if (flashLightObj) {
        [flashLightObj setFlashlightLevel:0.f withError:nil];
        [flashLightObj turnPowerOff];
    }
    if (dashboardButtonsVCInstance) {
        if ([dashboardButtonsVCInstance _isFlashlightOn]) {
            [dashboardButtonsVCInstance _toggleFlashlight];
        }
        return;
    }
    if (AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo])
        if ([device hasTorch]) {
            [device lockForConfiguration:nil];
            device.torchMode = AVCaptureTorchModeOff;
            [device unlockForConfiguration];
            return;
        }

}

void lockOrientation() {
	// Lock the device to portrait
	SBOrientationLockManager *lockManager = [%c(SBOrientationLockManager) sharedInstance];
	isUserLocked = [lockManager isUserLocked];
	userLockOrientation = [lockManager userLockOrientation];
	[lockManager lock:1];
}

void resetOrientation(){
	// Reset orientation lock
    SBOrientationLockManager *lockManager = [%c(SBOrientationLockManager) sharedInstance];
    if (isUserLocked) [lockManager lock:userLockOrientation];
    else [lockManager unlock];
}

void stopAndSaveScreenRecording() {
	if ([[%c(RPScreenRecorder) sharedRecorder] isRecording])
		[[%c(RPScreenRecorder) sharedRecorder] stopRecordingAndSaveToCameraRoll:nil];
}

void respring() {
	pid_t pid;
	const char *args[] = {"/usr/bin/killall", "SpringBoard", NULL};
	posix_spawn(&pid, args[0], NULL, NULL, (char* const*)args, NULL);
}

#pragma mark - IOHIDEventQueueEnqueue

/*
	This is the vital core of this effect.
	It is the function called in userspace to tell backboardd what inputs have been received on device hardware.
	It adds a IOHIDEvent to a queue to be sent to registered ports

	If the effect isnt enabled, enqueue the event as usual, but if it is then we dont send it to backboardd
	This allows the device to stay in deepsleep where as it would normally wake up from things like ambient light sensors ETC
	
	We can also detect if the event is a lock button and detect a hold for 3 seconds.
 */

extern "C" void IOHIDEventQueueEnqueue(IOHIDEventQueueRef queue, IOHIDEventRef event);
void (*old_Enqueue)(IOHIDEventQueueRef queue, IOHIDEventRef event);
void newEnqueue(IOHIDEventQueueRef queue, IOHIDEventRef event){
	
	if (!isEffectEnabled) {
		old_Enqueue(queue, event);
	}

	else {
		//Digitizer Event (TouchScreen)
		if(IOHIDEventGetType(event) == (unsigned)11){
			//Screen was touched, are we in OLED
			if(kOLED){
				//Tell Springboard that it got a tapToWake request with this Post Notification
				POST_NOTIF(WAKE_NOTIF)
			}
		}


		if (IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardUsage)==IOHID_POWER_BUTTON_USAGE_ID) {
			//Lock Button has been hit are we OLED?
			if(kOLED){
				//Turn on screen
				POST_NOTIF(WAKE_NOTIF)
				//iPads dont like to autoshut off well, lets fix that
				if ( [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"] ) {
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
						if(isEffectEnabled){POST_NOTIF(LOCK_NOTIF)}
				 	});
				}
			}	
			
			//Is the lock button down or up now?
			if (IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardDown)) {
				//Communicate with UX to do the progress bar.
				if(kOLED){POST_NOTIF("com.kurrtandsquiddy.powerup.oled.startWakeButton")}
				/*
					This starts a NSTimer when you initially press the button and invalidates it when you release the button
					That doesnt always work so we track its position so it has to still be down at (2) secs
				*/
				if(!holdTimer && !isPowerButtonDown){
					isPowerButtonDown = YES;
					dispatch_async(dispatch_get_main_queue(), ^{
						HBLogDebug(@"[PUP] Start Timer");
						holdTimer = [NSTimer scheduledTimerWithTimeInterval:WAKE_HOLD_POWER_SECS 				
   						repeats:NO
						block:^(NSTimer * _Nonnull timer){if(isPowerButtonDown) POST_NOTIF(DISABLE_NOTIF)}];
					});
				}
			}else if(!IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardDown)){
				isPowerButtonDown = NO;
				//Inval timer and post UI stuff
				if(holdTimer){
					dispatch_async(dispatch_get_main_queue(), ^{
						[holdTimer invalidate];
						holdTimer = nil;
					});	
				}
				if(kOLED){POST_NOTIF("com.kurrtandsquiddy.powerup.oled.stopWakeButton")}
				
			}
		}
	}
	
}


#pragma mark - Enable Proccess & Jobs

void enable_process_jobs() {
	tlog(@"enable_process_jobs");
	isEffectEnabled = YES;
	[[[%c(SpringBoard) sharedApplication] pluginUserAgent] lockAndDimDeviceDisconnectingCallIfNecessary:YES];
	externalTweakSupport();
	if ([[[NSProcessInfo processInfo].processName uppercaseString] isEqualToString:@"THERMALMONITORD"]) {
		// Throttle CPU
		if(kThrottle) lpm_throttle();
	} else if ([[[NSProcessInfo processInfo].processName uppercaseString] isEqualToString:@"SPRINGBOARD"]) {
		// SpringBoard

		// Stop and Save Screen Recording
		stopAndSaveScreenRecording();

		//You'll never guess what this call does /s LUL.
		turnOffFlash();

		//Show necessary UI stuff and lock orientation so it doesnt rotate.
		if(kOLED) {
			lockOrientation();
			[[ux sharedInstance] showOLEDwithPerc:[[%c(SBUIController) sharedInstance] batteryCapacityAsPercentage]];
		}else{
			lockOrientation();
			//failsafe black window.
			[[ux sharedInstance] showCurtain];
		}

		//Kill Background Apps
		killBackgroundApps();

		// Airplane mode
		enableAirplaneMode();

		//This is important for some reason, if i remove this it breaks even tho its default no. Dont @ me -Squiddy
		isPowerButtonDown = NO;

		// LPM
		enableLPM();

		//Lock Screen
		POST_NOTIF(LOCK_NOTIF)

		// Call deepsleep
		if(kDeepsleep){
			sleep(1);
			sleep_sys();
		}
	}

}

#pragma mark - Disable Proccess & Jobs

void disable_process_jobs() {
	tlog(@"disable_process_jobs");
	isEffectEnabled = NO;
	externalTweakSupport();
	
	if ([[[NSProcessInfo processInfo].processName uppercaseString] isEqualToString:@"THERMALMONITORD"]) {
		// Thermalmonitord
		// Throttle
		if(kThrottle) lpm_dethrottle();
	} else if ([[[NSProcessInfo processInfo].processName uppercaseString] isEqualToString:@"SPRINGBOARD"]) {
		// SpringBoard
		if (kRespringToWake) {
			// If respringing to wake we dont want to do anything with the UI
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{respring();});
			resetOrientation();
			returnAirplaneMode();
			returnLPM();
			if(kDeepsleep) wake_sys();
			return;
		}
		if(kOLED) [[ux sharedInstance] hideOLED];
		else [[ux sharedInstance] hideCurtain];
		resetOrientation();
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{[[%c(SBLockScreenManager) sharedInstance] _wakeScreenForTapToWake];});
		// Call wake
		if(kDeepsleep) wake_sys();
		// Airplane mode
		returnAirplaneMode();
		// LPM
		returnLPM();
		// Call wake
	}
}



void loadPrefs(){
	NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.kurrtandsquiddy.powerup"];
	if (prefs) {
		kEnabled            =      [prefs objectForKey:@"kEnabled"] ? [[prefs objectForKey:@"kEnabled"] boolValue] : kEnabled;
		kAutoWake           =      [prefs objectForKey:@"kAutoWake"] ? [[prefs objectForKey:@"kAutoWake"] boolValue] : kAutoWake;
		kAutoWakePercent    =      [prefs objectForKey:@"kAutoWakePercent"] ? [[prefs objectForKey:@"kAutoWakePercent"] floatValue] : DEFAULT_AUTO_WAKE_PERC;
		kOLED               =      [prefs objectForKey:@"kOLED"] ? [[prefs objectForKey:@"kOLED"] boolValue] : kOLED;
		kDeepsleep          =      [prefs objectForKey:@"kDeepsleep"] ? [[prefs objectForKey:@"kDeepsleep"] boolValue] : kDeepsleep;
		kDaemon             =      [prefs objectForKey:@"kDaemon"] ? [[prefs objectForKey:@"kDaemon"] boolValue] : kDaemon;
		kThrottle           =      [prefs objectForKey:@"kThrottle"] ? [[prefs objectForKey:@"kThrottle"] boolValue] : kThrottle;
		kUnplugWakeDelay	=	   [prefs objectForKey:@"kUnplugWakeDelay"] ? [[prefs objectForKey:@"kUnplugWakeDelay"] floatValue] : kUnplugWakeDelay;
		kRespringToWake		=	   [prefs objectForKey:@"kRespringToWake"] ? [[prefs objectForKey:@"kRespringToWake"] boolValue] : kRespringToWake;
	}

	//If autowake is 0 or kAutoWake is off never be able to meet AutoWake percent
	if(!kAutoWake || kAutoWakePercent == 0) kAutoWakePercent = 101;
	
	
}

%ctor {
	
	loadPrefs();

	//Manually hook IOHIDEventQueueEnqueue
	MSHookFunction(&IOHIDEventQueueEnqueue,&newEnqueue,&old_Enqueue);

	// Listen for prefs change
	LISTEN_NOTIF(loadPrefs, "com.kurrtandsquiddy.powerup/settingschanged")

	//I dont know why i have to set this here, i set it when i delcare but if i dont do this it starts as true
	

	// All processes need to listen for these
	LISTEN_NOTIF(enable_process_jobs, ENABLE_NOTIF)
	LISTEN_NOTIF(disable_process_jobs, DISABLE_NOTIF)

	
	if ([[[NSProcessInfo processInfo].processName uppercaseString] isEqualToString:@"THERMALMONITORD"]) {
		//This group need only be hooked in TMD
		%init(thermalmonitord);
	} else if ([[[NSProcessInfo processInfo].processName uppercaseString] isEqualToString:@"SPRINGBOARD"]) {
		//Listen for these cause it can only be done from within SB
		LISTEN_NOTIF(lockAndDimDevice, LOCK_NOTIF)
		LISTEN_NOTIF(wakeScreen, WAKE_NOTIF)
		
	
	if(isEffectEnabled)	POST_NOTIF(DISABLE_NOTIF) // Failsafe
	}

	%init(); // init ungrouped
}
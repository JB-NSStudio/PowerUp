// Global header file

// Avoid duplicate
#ifndef GLOBAL_LOADED
#define GLOBAL_LOADED // Flag that this has been used

// Bring in required headers
#import "NSTask.h"
#import <spawn.h>
#include <sys/wait.h>
#import <signal.h>
#include <sys/types.h>
#include <signal.h>


// Constants
#define TWEAK_ABBR                              "PUP"
#define BUNDLE_ID                               "com.kurrtandsquiddy.powerup"
#define ENABLE_NOTIF                            BUNDLE_ID"/enable"
#define DISABLE_NOTIF                           BUNDLE_ID"/disable"
#define WAKE_NOTIF                              BUNDLE_ID"/wakescreen"
#define LOCK_NOTIF                              BUNDLE_ID"/lockscreen"
#define KEEP_AWAKE_REASON                       @"com.kurrtandsquiddy.keepawake"
#define WAKE_HOLD_POWER_SECS                    2
#define IOHID_POWER_BUTTON_USAGE_ID             48
#define ROOT_ME_PLS_BIN                         "/Library/Application Support/PowerUp.bundle/PowerUp_RootMePls"
#define PLIST_PATH                              "/System/Library/LaunchDaemons/"
#define SB_PLIST                                PLIST_PATH"com.apple.SpringBoard.plist"
#define DEFAULT_AUTO_WAKE_PERC                  20



// Convenience Macros
#define POST_NOTIF(_name)                       CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),\
                                                CFSTR(_name), NULL, NULL, YES);
#define LISTEN_NOTIF(_call, _name)              CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),\
                                                NULL, (CFNotificationCallback)_call, CFSTR(_name), NULL, CFNotificationSuspensionBehaviorCoalesce);
#define ROOT_ME_PLS(_cmd)                       pid_t pid;\
                                                const char* args[] = {""ROOT_ME_PLS_BIN, #_cmd, NULL};\
                                                posix_spawn(&pid, args[0], NULL, NULL, (char* const*)args, NULL);
#define KILL_RMP                                pid_t pid;\
                                                const char* args[] = {""ROOT_ME_PLS_BIN, "die", NULL};\
                                                posix_spawn(&pid, args[0], NULL, NULL, (char* const*)args, NULL);

#define PREFS(_boolVal)                          [[prefs objectForKey:@#_boolVal] boolValue]

#endif
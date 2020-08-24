#include <spawn.h>
#import <dlfcn.h>
#import <IOKit/pwr_mgt/IOPMLibPrivate.h>
#include"../global.h"

#define FLAG_PLATFORMIZE (1 << 1)

#define SELF_TOOL_NAME     "PowerUp_RootMePls"

IONotificationPortRef notifyPortRef;
io_connect_t pmcon;
io_object_t notifierObject;
bool is_sleep_runner = false;

void sleepSystem();

// Cleans up resources when sigterm is recieved
void clean_up() {
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopCommonModes);
    IODeregisterForSystemPower(&notifierObject);
    IOServiceClose(pmcon);
    IONotificationPortDestroy(notifyPortRef);
}

// Triggered when SIGTERM is sent to this process
void handle_sigterm(int signum) {
    // Clean up, we done here.
    if (is_sleep_runner) clean_up();
    exit(EXIT_SUCCESS);
}

// Privs stuff
void platformize_me() {
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) return;
    
    // Reset errors
    dlerror();
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
    
    const char *dlsym_error = dlerror();
    if (dlsym_error) return;
    
    ptr(getpid(), FLAG_PLATFORMIZE);
}

// Privs stuff
void patch_setuid() {
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) return;
    
    // Reset errors
    dlerror();
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t ptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");
    
    const char *dlsym_error = dlerror();
    if (dlsym_error) return;
    
    ptr(getpid());
}

// Callback to handle system power changes. In our case we want to keep sleeping if anything changes and approve the sleep requests.
void PowerCallBack(void* refCon, io_service_t service, natural_t messageType, void * messageArgument) {
    if (pmcon) {
        switch (messageType) {
            case kIOMessageSystemHasPoweredOn:
                IOPMSleepSystem(pmcon);
                break;
            case kIOMessageSystemWillSleep:
                IOAllowPowerChange(pmcon, (long)messageArgument);
                break;
            case kIOMessageSystemWillPowerOn:
                IOCancelPowerChange(pmcon, (long)messageArgument); // unsure if this actually does anything, so sleep again pls
                IOPMSleepSystem(pmcon);
                break;
        }
    }
}

// Tell the system to sleep
// Here we could set the keys for deepsleep or hibernation, but these keys do not get used on iOS.
// Deepsleep and hibernation are mac specific and are not possible in iOS.
// For more information on this refer to the submodule for this project "IOPMKeyChecker" where we have built a tool
// to verify if certain IOPM keys even get set on your current device.
//
// Thank you to userlandkernel (Twitter: @userlandkernel) and code2k on Github for the following repositories that
// helped us understand this process. Check them out if you want to learn more about sleeping the system with IOKit.
// https://github.com/userlandkernel/deepsleep
// https://github.com/code2k/Deep-Sleep.wdgt
void sleepSystem() {
    // We store a variable to signal that the current process is forcing sleep so we can clean up appropriately if signalled.
    is_sleep_runner = true;

    void *refCon = NULL;
    // Register for power changes
    pmcon = IORegisterForSystemPower(refCon, &notifyPortRef, PowerCallBack, &notifierObject);
    if (pmcon == 0) exit(1);

    // Get the current runloop and slip in that bad boy!
    CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopCommonModes);
    
    // Call sleep until we recieve a signal
    if (IOPMSleepSystem(pmcon) == kIOReturnSuccess) CFRunLoopRun();

    // Just incase we reach this point, we clean up before exiting
    clean_up();
}
void kill_apps(){
    NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/bin/bash"];
	[task setArguments:@[ @"/Library/Application Support/PowerUp.bundle/nukeprocs.sh" ]];
	[task launch];
    [task waitUntilExit];
}

// Send a SIGTERM to any process with this ones name, called here as we want root to send it.
void kill_self() {
    pid_t pid;
    const char *argv[] = {"killall", "-15", SELF_TOOL_NAME, NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
}

int main(int argc, char **argv, char **envp) {
    @autoreleasepool {
        // Prepare to respond to sigterms
        struct sigaction action;
        memset(&action, 0, sizeof(struct sigaction));
        action.sa_handler = handle_sigterm;
        sigaction(SIGTERM, &action, NULL);
        // Prepare for and perform setuid(0)
        patch_setuid();
        platformize_me();
        setuid(0);
        setuid(0); // Apparently that we need to call this twice for some jailbreaks.
        // Exit if no argument provided
		if (argc<2) {
			printf("ERROR: A valid command argument must be provided\n");
			exit(EXIT_FAILURE);
		}
        // Act according to argument(s)
		if (strcmp(argv[1], "sleep") == 0) sleepSystem();
		else if (strcmp(argv[1], "die") == 0) kill_self();
        else if (strcmp(argv[1], "killapps") == 0) kill_apps();
		else printf("ERROR: Invalid command argument\n");
    }
    return 0;
}

// MAKE SURE TO SET THE PERMISSIONS TO 6755
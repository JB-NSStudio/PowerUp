#include <stdio.h>
#include <unistd.h>
#import <dlfcn.h>
#import <IOKit/pwr_mgt/IOPMLibPrivate.h>
#import <mach/mach_error.h>

// Flags
#define _HELP                   "--help"
#define _HIBERNATE_MODE         "-h"
#define _HIBERNATE_MODE_LONG    "--hibernate"
#define _STAND_BY               "-d"
#define _STAND_BY_LONG          "--deepsleep"
#define _CUSTOM                 "-c"
#define _CUSTOM_LONG            "--custom"

// Quick Check Keys
#define _HIBERNATE_KEY          "Hibernate Mode"
#define _DEEP_SLEEP_KEY         "Standby Enabled" // This == kIOPMDeepSleepEnabledKey

// Results for printing
#define _SUCCESS_PRT            "[SUCESS]\n"
#define _ERROR_PRT(_err)        "[ERROR] ("_err")\n"
#define _ERROR_PRTV(_err)       "%s", [[NSString stringWithFormat:@"[ERROR] (%@)\n", [NSString stringWithUTF8String:_err]] UTF8String] // ew...
#define _FAIL_PRT               "[FAIL]\n"

#define _SEPARATOR              "---------------------------"

// Convenience Macros
#define CFSTRV(_cstr)           ((CFStringRef)[NSString stringWithUTF8String:_cstr]) // CFSTR doesn't support variables


// Display the help menu
void show_help() {
	printf("\n\nIOPMKeyChecker\n");
	printf("Check if IOPM Preferences Keys are valid on the current device.\n");
	printf("This tool simply attempts to set the given key. If the key is successfully saved we assume it is valid.\n");
	printf("If a key is set successfully it is possible that IOKit still does not make use of the key, you will then need \
to perform further testing.\n");
	printf("It is possible for keys to be set and still return false here, however it is extremely unlikely IOKit will \
ever retrieve this key as it is ignored by the general IOKit retrieval method. Personal testing has indicated IOKit \
ignores these types of keys.\n");
	printf("All keys will be reset to their original values afterwards.\n\n");
	printf("By Kurrt and Squiddy.\n\n");
	printf("Usage:\n");
	printf("%-15s Show this help menu.\n", _HELP);
	printf("%-15s Check if Hibernate Mode exists.\n", _HIBERNATE_MODE);
	printf("%-15s Check if Hibernate Mode exists.\n", _HIBERNATE_MODE_LONG);
	printf("%-15s Check if Deep Sleep (AKA Stand By) exists.\n", _STAND_BY);
	printf("%-15s Check if Deep Sleep (AKA Stand By) exists.\n", _STAND_BY_LONG);
	printf("%-15s Check a custom key. (The key must follow)\n", _CUSTOM);
	printf("%-15s Check a custom key. (The key must follow)\n", _CUSTOM_LONG);
}

// Comparison method
bool compare_saved_values(const char *key, CFNumberRef comp_val, const char *sub) {
	SInt32 check_value, comp_value;
	CFDictionaryRef check_dict = IOPMCopyPMPreferences();
	if (sub) check_dict = CFDictionaryGetValue(check_dict, CFSTRV(sub));
	if (!check_dict) return false;
	CFNumberRef check_value_ref = CFDictionaryGetValue(check_dict, CFSTRV(key));
	if (!check_value_ref) {
		CFRelease(check_dict);
		return false;
	}
	CFNumberGetValue(check_value_ref, kCFNumberSInt32Type, &check_value);
	CFNumberGetValue(comp_val, kCFNumberSInt32Type, &comp_value);
	CFRelease(check_dict);
	CFRelease(check_value_ref);
	return (check_value == comp_value);
}

// Set value method (0 = error, 1 = success, 2 = fail)
int set_value(const char *key, CFNumberRef value, CFDictionaryRef orig_dict, const char *sub) {
	CFMutableDictionaryRef alter_dict = NULL;
	if (sub) {
		CFDictionaryRef tmp_d = CFDictionaryGetValue(orig_dict, CFSTRV(sub));
		if (!tmp_d) tmp_d = (__bridge CFDictionaryRef)@{};
		alter_dict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, tmp_d);
	} else {
		alter_dict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, orig_dict);
	}
	CFDictionarySetValue(alter_dict, CFSTRV(key), value);
	if (sub) {
		CFMutableDictionaryRef m_orig_dict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, orig_dict);
		CFDictionarySetValue(m_orig_dict, CFSTRV(sub), (CFDictionaryRef)alter_dict);
		alter_dict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, m_orig_dict);
		CFRelease(m_orig_dict);
	}
	bool err = (IOPMSetPMPreferences((CFDictionaryRef)alter_dict) != kIOReturnSuccess);
	sleep(1); // Just incase as this writes to disk and we dont know if there's any async work done.
	bool res = compare_saved_values(key, value, sub);
	// Clean Up
		
	CFRelease(alter_dict);
	return (err)?0:((res)?1:2);
}

// Try to set the requested key
void try_key(char *key) {
	printf("Checking if %s is valid for this device...\n", key);

	int res;

	// Grab the current dictionary to restore later
	printf("%-58s", "Fetching current keys to restore later...");
	CFDictionaryRef orig_dict = IOPMCopyPMPreferences();

	if (!orig_dict) {
		printf(_ERROR_PRT("IOPMCopyPMPreferences Failed"));
		return;
	} else {
		printf(_SUCCESS_PRT);
	}

	// We try setting the value to 0 then 1. First we create the CF Refs for the values.
	SInt32 one_val = 1, zero_val = 0;
	CFNumberRef one_value_ref  = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &one_val),
    			zero_value_ref = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &zero_val);


	// Try root values
	bool root_result = false;
	bool root_err = false;
	printf("%-58s", "Trying to set key in root dictionary...");

	// Try zero value
	res = set_value(key, zero_value_ref, orig_dict, NULL);
	root_err = !(res);
	root_result = (res==1);

	// Proceed only if zero passes
	if (root_result) {
		// Try one value
		res = set_value(key, one_value_ref, orig_dict, NULL);
		root_err = !(res);
		root_result = (res==1);
	}

	// Show result
	if (root_err) printf(_ERROR_PRT("Unknown Error."));
	else if (root_result) printf(_SUCCESS_PRT);
	else printf(_FAIL_PRT);



	// Try kIOPMUPSPowerKey values
	bool upsp_result = false;
	bool upsp_err = false;
	printf("%-58s", "Trying to set key in kIOPMUPSPowerKey dictionary...");

	// Try zero value
	res = set_value(key, zero_value_ref, orig_dict, kIOPMUPSPowerKey);
	upsp_err = !(res);
	upsp_result = (res==1);

	// Proceed only if zero passes
	if (upsp_result) {
		// Try one value
		res = set_value(key, one_value_ref, orig_dict, kIOPMUPSPowerKey);
		upsp_err = !(res);
		upsp_result = (res==1);
	}

	// Show result
	if (upsp_err) printf(_ERROR_PRT("Unknown Error."));
	else if (upsp_result) printf(_SUCCESS_PRT);
	else printf(_FAIL_PRT);



	// Try kIOPMBatteryPowerKey values
	bool bp_result = false;
	bool bp_err = false;
	printf("%-58s", "Trying to set key in kIOPMBatteryPowerKey dictionary...");

	// Try zero value
	res = set_value(key, zero_value_ref, orig_dict, kIOPMBatteryPowerKey);
	bp_err = !(res);
	bp_result = (res==1);

	// Proceed only if zero passes
	if (bp_result) {
		// Try one value
		res = set_value(key, one_value_ref, orig_dict, kIOPMBatteryPowerKey);
		bp_err = !(res);
		bp_result = (res==1);
	}

	// Show result
	if (bp_err) printf(_ERROR_PRT("Unknown Error."));
	else if (bp_result) printf(_SUCCESS_PRT);
	else printf(_FAIL_PRT);



	// Try kIOPMACPowerKey values
	bool macp_result = false;
	bool macp_err = false;
	printf("%-58s", "Trying to set key in kIOPMACPowerKey dictionary...");

	// Try zero value
	res = set_value(key, zero_value_ref, orig_dict, kIOPMACPowerKey);
	macp_err = !(res);
	macp_result = (res==1);

	// Proceed only if zero passes
	if (macp_result) {
		// Try one value
		res = set_value(key, one_value_ref, orig_dict, kIOPMACPowerKey);
		macp_err = !(res);
		macp_result = (res==1);
	}

	// Show result
	if (macp_err) printf(_ERROR_PRT("Unknown Error."));
	else if (macp_result) printf(_SUCCESS_PRT);
	else printf(_FAIL_PRT);


	// Reset to original state
	printf("%-58s", "Resetting preferences...");
	IOReturn ret = IOPMSetPMPreferences(orig_dict);
	const char *err_m = mach_error_string(ret);
	if (ret!=kIOReturnSuccess) printf(_ERROR_PRTV(err_m));
	else printf(_SUCCESS_PRT);

	// Clean up
	printf("%-58s", "Cleaning Up...");
	CFRelease(orig_dict);
	CFRelease(one_value_ref);
	CFRelease(zero_value_ref);
	printf(_SUCCESS_PRT);


	// Display overall result
	printf("\nResult: %s\n", (root_result||upsp_result||bp_result||macp_result)?"Success":"Fail");

	// Explain for Quick Check Keys
	if (strcmp(_HIBERNATE_KEY, key)==0) 		printf("\nHibernation is%s possible on this device.\n", (root_result||upsp_result||bp_result||macp_result)?"":" not");
	else if (strcmp(_DEEP_SLEEP_KEY, key)==0) 	printf("\nDeep sleep is%s possible on this device.\n", (root_result||upsp_result||bp_result||macp_result)?"":" not");
}


int main(int argc, char **argv, char **envp) {
	@autoreleasepool {
		printf("\n%s\n\n", _SEPARATOR);
		if(getuid()!=0) {
			// If we get here we do not have root privileges.
			printf("ERROR: This tool must be run as root.\n");
			printf("\n%s\n\n", _SEPARATOR);
			return 1;
		}
		if (argc==1) {
			// No argument provided. Show the user the help menu.
			printf("ERROR: A valid argument must be provided. Showing help.\n\n");
			show_help();
			printf("\n%s\n\n", _SEPARATOR);
			return 1;
		}
		if (strcmp(argv[1], _HELP) == 0)                                                                show_help();
		else if (strcmp(argv[1], _HIBERNATE_MODE) == 0 || strcmp(argv[1], _HIBERNATE_MODE_LONG) == 0)   try_key(_HIBERNATE_KEY);
		else if (strcmp(argv[1], _STAND_BY) == 0 || strcmp(argv[1], _STAND_BY_LONG) == 0)               try_key(_DEEP_SLEEP_KEY);
		else if ((strcmp(argv[1], _CUSTOM) == 0 || strcmp(argv[1], _CUSTOM_LONG) == 0) && argc>2)       try_key(argv[2]);
		else printf("ERROR: Invalid argument.\n");
		printf("\n%s\n\n", _SEPARATOR);
	}
	return 0;
}

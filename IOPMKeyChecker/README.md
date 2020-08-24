# IOPMKeyChecker
This is a simple tool to test if IOPMPreferences keys exist for the current device.

![Screenshot](https://github.com/Kurrt/IOPMKeyChecker/blob/master/screenshot.png)

#### Note: Built for and tested on iOS. MacOS may work but may need some adjustments

In MacOS and iOS the IOPMPreferences dictionary allows you to manage how the device responds to power management changes through IOKit. Personal testing has shown that iOS completely ignores the values set, but this acts as a helper to check if the keys can be set and help reduce time wasted when testing these keys.

## How it works
This tool simply attempts to set the dictionary values for the provided key. It first attempts to set the key in the root dictionary, followed by the subdictionaries. Each attempt sets the value to 0, checks if the key is set to 0 in the saved result, then attempts again with 1. (This helps avoid false positives if the key already exists and the value is 0).

Once all tests are complete the original settings are restored to reset the state.

If a key succeeds you can then perform further testing on that key to ensure it is used and works in the expected way.

## "But IOKit contains a method to retrieve unsupported keys from IOPMPreferences"
This is correct. Internal methods exist to retrieve the keys even when not supported on the current device. It is possible IOKit uses these keys at some point but this would be unusual and testing has shown they are not used in any significant way. This tool cannot clarify that and should only be used as part of your testing.

## Usage
1. Copy the binary from the bin folder or release onto your device.
2. Navigate to the location of the binary.
3. Execute the program. To see the help menu use the flag ```--help```

## Examples
- A working key on iPhone 11 Pro Max iOS 13.5 is ```PrioritizeNetworkReachabilityOverSleep```:
  ```
  iopmcheck -c PrioritizeNetworkReachabilityOverSleep
  ```
- An **invalid** key on iPhone 11 Pro Max iOS 13.5 is ```Hibernate Mode```:
  ```
  iopmcheck -c "Hibernate Mode"
  ```

## Quick Tests
2 keys are built in to check for "hibernation" and "deep sleep" (AKA stand by). 
- To check for hibernation use the flag ```-h``` or ```--hibernation```
- To check for deep sleep use the flag ```-d``` or ```--deepsleep```

## Custom Keys
To check other keys use the flag ```-c``` or ```--custom``` followed by your desired key.

## Us
This tool was built by [Kurrt](https://github.com/Kurrt "Kurrt's Github") and [Squiddy](https://github.com/Squidkingdom "Squiddy's Github")

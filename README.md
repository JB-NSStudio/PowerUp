# PowerUp
Speed up charging by entering a super low power state while plugged in.
<br/><br/>
## What does the low power state do?
- Sleeps the system using built in IOKit methods. (We refer to this as deepsleep in settings for user clarity)
- Turns on aeroplane plane mode.
- Enables low power mode.
- Throttles the system using methods in thermalmonitord.
- Stops and saves screen recordings.
- Turns off flashlight.
- Kills all open applications.
- Blocks input passthrough.
- Turns off display.
<br/><br/>

## Does this tweak use hibernation?
This tweak uses the same process other tweaks that claim to use hibernation do but hibernation and deep sleep do not exist in iOS in the same way they do in MacOS. We have built a tool that can be run on an iOS device to confirm what IOPM Preferences can be set within iOS [here](https://github.com/Kurrt/IOPMKeyChecker). Currently all devices we have tested do no support either of these options so setting them would be reckless as they require writing to disk. If iOS begins to make use of these settings, deep sleep and or hibernation will be added at a later date.
<br/><br/>
## Repo
PowerUp can currently be found on the following repos:
- https://kurrt.com/repo
- https://repo.squiddy.dev
- https://repo.community
<br/><br/>
## Credits
- [UserlandKernel](https://github.com/userlandkernel) for sharing the project [DeepSleep](https://github.com/userlandkernel/deepsleep)
- [Code2K](https://github.com/code2k) for sharing the project [Deep Sleep Widget](https://github.com/code2k/Deep-Sleep.wdgt)
- [Ryan Petrich](https://github.com/rpetrich) for sharing the project [Powercuff](https://github.com/rpetrich/Powercuff)
<br/><br/>
## PowerUp creators
- [Kurrt](https://github.com/Kurrt) (Twitter: [@KurrtDev](https://twitter.com/KurrtDev))
- [Squiddy](https://github.com/Squidkingdom) (Twitter: [@Squidkingdom](https://twitter.com/squidkingdom))

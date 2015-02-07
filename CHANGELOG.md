# Airbrake iOS Notifier Changelog
## 4.1
- bug fixes
## 4.0 beta
- JSON format crash report.
- add username parameter to ABNotifier. 
- raised support floor to iOS 5.0
- Asyncnously http request. 
## 3.1

- add new environment strings to differentiate between development and testing
- add parameter to main start method to control display of crash prompt

## 3.0

- all new public API
- all new notice file format
- raised support floor to iOS 4.0 and Mac OS 10.7
- new method to log your own exceptions
- use asynch reachability events
- add notifications that mirror delegate callbacks
- UDID is no longer automatically transmitted because it is [deprecated](http://caleb.dvnprt.me/blog/2011-08-19-udid.html)
- bug fixes

## 2.2.2

- fix compile error caused by an incorrect import when building for iOS

## 2.2.1

- add automatic environment name that sets its value based on the DEBUG macro

## 2.2

- UDID is posted in all DEBUG builds by default
- improved error handling to makre sure corrupt notices don't cause issues
- use regex for callstack parsing
- added Traditional Chinese localization
- environment info is now posted in signal notices
- fixed bug where some delegate methods weren't called on the main thread
- added app version to notice payload for filtering
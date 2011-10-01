# Airbrake iOS Notifier Changelog

## 3.0

- all new public API
- all new notice file format
- raised support floor to iOS 4.0 and Mac OS 10.7
- new method to log your own exceptions
- use asynch reachability events
- add notifications that mirror delegate callbacks
- UDID is no longer automatically transmitted because it is [deprecated](http://blog.guicocoa.com/post/9137000491/what-apple-should-have-done-with-udid)
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
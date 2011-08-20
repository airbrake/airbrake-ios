# About

The Airbrake iOS Notifier is designed to give developers instant notification of problems that occur in their apps. With just a few lines of code and a few extra files in your project, your app will automatically phone home whenever a crash or exception is encountered. These reports go straight to [Airbrake](http://airbrakeapp.com) where you can see information like backtrace, device type, app version, and more.

To see how this might help you check out [this screencast](http://guicocoa.com/hoptoad#screencast). If you have questions or need support please visit [Airbrake support](http://help.airbrakeapp.com/discussions/ios-notifier)

#Signals

The notifier handles all unhandled exceptions, and a select list of Unix signals:

- SIGABRT
- SIGBUS
- SIGFPE
- SIGILL
- SIGSEGV
- SIGTRAP

# Symbolication

In order for the call stack to be properly symbolicated at the time of a crash, applications built with the notifier should not be stripped of their symbol information at compile time. If these settings are not set as  recommended, frames from your binary will be displayed as hex return addresses instead of readable strings. These hex return addresses can be symbolicated using `atos`. More information about symbolication and these build settings can be found in Apple's [developer documentation](http://developer.apple.com/tools/xcode/symbolizingcrashdumps.html). Here are the settings that control code stripping:

- Deployment Postprocessing: Off
- Strip Debug Symbols During Copy: Off
- Strip Linked Product: Off

# Versioning

Airbrake supports a version floor for reported notices. A setting called "Latest app version" is available in your project settings that lets you specify the lowest app version for which crashes will be saved. This version is compared using [semantic versioning](http://semver.org/). The notifier uses your `CFBundleVersion` to make this comparison. If you have apps in the wild that are using an older notifier version and don't report this bundle version, the notices will dropped by Airbrake. For more information on how this is implemented, read this [knowledge base article](http://help.airbrakeapp.com/kb/ios/app-versions).

# Installation

1. Drag the Airbrake folder to your project
    
    - Make sure "Copy Items" and "Create Groups" are selected

2. Add `SystemConfiguration.framework`, `libicucore.dylib`, and `libxml2.dylib` to your project

3. Add the path `/usr/include/libxml2` to Header Search Paths in your project's build settings
  
    - make sure you add it under "All Configurations"

4. Check the supported localizations of your App under your project settings

    - XCode will automaticly add all languages Airbreak notifier supports to the list of supported languages of your App. So you might want to delete some of them.

The HTNotifier class is the primary class you will interact with while using the notifier. All of its methods and properties, along with the HTNotifierDelegate protocol are documented in their headers. Please read through the header files for a complete reference of the library.

## Upgrading
Please remove all of the resources used by the notifier from your project before upgrading. This is the best way to make sure all of the appropriate files are present and no extra files exist
    
# Running The Notifier

The `HTNotifier` class is the primary class you will interact with while using the notifier. All of its methods and properties, along with the `HTNotifierDelegate` protocol are documented in their headers. **Please read through the header files for a complete reference of the library.**

To run the notifier you only need to complete two steps. First, import the `HTNotifier` header file in your app delegate

    #import "HTNotifier.h"
    
Next, call the main notifier method at the very beginning of your `application:didFinishLaunchingWithOptions:`

    [HTNotifier startNotifierWithAPIKey:@"<# api key #>"
                        environmentName:@"<# environment name #>"
                                 useSSL:YES // only if your account supports it
                               delegate:self];

The API key argument expects your Airbrake project API key. The environment name you provide will be used to categorize received crash reports in the Airbrake web interface. The notifier provides several factory environment names that you are free to use.

- `HTNotifierDevelopmentEnvironment`
- `HTNotifierAdHocEnvironment`
- `HTNotifierAppStoreEnvironment`
- `HTNotifierReleaseEnvironment`

It also provides an environment called `HTNotifierAutomaticEnvironment` which will set the environment to release or development depending on the presence of the `DEBUG` macro

# Environment Variables

Airbrake notices support custom environment variables. To add your own values to this part of the notice, use the "environmentValue" family of methods found in `HTNotifier.h`

# Exception Logging

As of version 3 of the notifier, you can log your own exceptions at any time.

    @try {
        // something dangerous
    }
    @catch (NSException *e) {
        [HTNotifier logException:e];
    }

# Debugging

To test that the notifier is working inside your application, a simple test method is provided. This method raises an exception, catches it, and reports it as if a real crash happened. Add this code to your `application:didFinishLaunchingWithOptions:` to test the notifier:

     [HTNotifier writeTestNotice];

If you use the `DEBUG` macro to signify development builds the notifier will log notices and errors to the console as they are encountered to help see more details

#Implementing the Delegate Protocol

The `HTNotifierDelegate` protocol allows you to respond to actions going on inside the notifier as well as provide runtime customizations. In version 3 of the notifier a matching set of notifications are posted to `NSNotificationCenter`. All of the delegate methods in the `HTNotifierDelegate` protocol are documented in the `HTNotifierDelegate.h`. Here are just a few of those methods:

MyAppDelegate.h

    #import HTNotifier.h
    
    @interface MyAppDelegate : NSObject <UIApplicationDelegate, HTNotifierDelegate> {
      // your ivars
    }
    
    // your properties and methods
    
    @end  

MyAppDelegate.m

    @implementation MyAppDelegate
      
      // your other methods
      
      #pragma mark - HTNotifierDelegate
      /*
        These are only a few of the delegate methods you can implement
        The rest are documented in HTNotifierDelegate.h
        All of the delegate methods are optional
      */
      - (void)notifierWillDisplayAlert {
        [gameController pause];
      }
      - (void)notifierDidDismissAlert {
        [gameController resume];
      }
      - (NSString *)titleForNoticeAlert {
        return @"Oh Noes!";
      }
      - (NSString *)bodyForNoticeAlert {
        return @"MyApp has detected unreported crashes, would you like to send a report to the developer?";
      }
      
    @end

#Contributors

- [Caleb Davenport](http://guicocoa.com)
- [Marshall Huss](http://twoguys.us)
- [Matt Coneybeare](http://coneybeare.net)
- [Benjamin Broll](http://twitter.com/bebroll)
- Sergei Winitzki
- Irina Anastasiu
- [Jordan Breeding](http://jordanbreeding.com)
- [LithiumCorp](http://lithiumcorp.com)
- [Mathijs Kadijk](http://www.wrep.nl/)
#About

The Hoptoad iOS Notifier is designed to give developers instant notification of problems that occur in their apps. With just a few lines of code and a few extra files in your project, your app will automatically phone home whenever a crash or exception is encountered. These reports go straight to [Hoptoad](http://hoptoadapp.com) where you can see information like backtrace, device type, app version, and more.

To see how this might help you check out [this screencast](http://guicocoa.com/hoptoad#screencast). If you have questions or need support please visit [Hoptoad support](http://help.hoptoadapp.com/discussions/ios-notifier)

#Signals

The notifier handles all unhandled exceptions, and a select list of Unix signals:

- SIGABRT
- SIGBUS
- SIGFPE
- SIGILL
- SIGSEGV
- SIGTRAP

#Symbolication

In order for the call stack to be properly symbolicated at the time of a crash, applications built with the notifier should not be stripped of their symbol information at compile time. If these settings are not set as  recommended, frames from your binary will be displayed as hex return addresses instead of readable strings. These hex return addresses can be symbolicated using `atos`. More information about symbolication and these build settings can be found in Apple's [developer documentation](http://developer.apple.com/tools/xcode/symbolizingcrashdumps.html). Here are the settings that control code stripping:

- Deployment Postprocessing: Off
- Strip Debug Symbols During Copy: Off
- Strip Linked Product: Off

#Versioning

Hoptoad supports a version floor for reported notices. A setting called "Latest app version" is available in your project settings that lets you specify the lowest app version for which crashes will be saved. This version is compared using [semantic versioning](http://semver.org/). The notifier uses your `CFBundleVersion` to make this comparison. If you have apps in the wild that are using an older notifier version and don't report this bundle version, the notices will dropped by Hoptoad. For more information on how this is implemented, read this [knowledge base article](http://help.hoptoadapp.com/kb/ios/app-versions).

#Installation

1. Drag the hoptoadnotifier, kissxml, and regexkitlite folders to your project
    
    - Make sure "Copy Items" and "Create Groups" are selected
    
    - If you are already using kissxml or regexkitlite, you do not need to include them again

2. Add SystemConfiguration.framework, libicucore.dylib, and libxml2.dylib to your project

3. Add the path /usr/include/libxml2 to Header Search Paths in your project's build settings
  
    - make sure you add it under "All Configurations"

The HTNotifier class is the primary class you will interact with while using the notifier. All of its methods and properties, along with the HTNotifierDelegate protocol are documented in their headers. Please read through the header files for a complete reference of the library.

##Upgrading
Please remove all of the resources used by the notifier from your project before upgrading. This is the best way to make sure all of the appropriate files are present and no extra files exist
    
#Running The Notifier

To run the notifier you only need to complete two steps. First, import the HTNotifier header file in your app delegate

    #import "HTNotifier.h"
    
Next, call the main notifier method at the very beginning of your `application:didFinishLaunchingWithOptions:`

    [HTNotifier startNotifierWithAPIKey:@"<# api key #>"
                        environmentName:@"<# environment #>"];

The API key argument expects your Hoptoad project API key. The environment name you provide will be used to categorize received crash reports in the Hoptoad web interface. The notifier provides several factory environment names that you are free to use.

- `HTNotifierDevelopmentEnvironment`
- `HTNotifierAdHocEnvironment`
- `HTNotifierAppStoreEnvironment`
- `HTNotifierReleaseEnvironment`

It also provides an environment called `HTNotifierReleaseEnvironment` which will set the environment to release or development depending on the presence of the DEBUG macro

#Debugging

To test that the notifier is working inside your application, a simple test method is provided. This method raises an exception, catches it, and reports it as if a real crash happened. Add this code to your `application:didFinishLaunchingWithOptions:` to test the notifier:

     [[HTNotifier sharedNotifier] writeTestNotice];

If you use the DEBUG macro to signify development builds the notifier will do a few special things for you:

- log notices to the console as they are posted to help see notice details
- automatically include the UDID of the device to help identify who submitted a crash

#Implementing the HTNotifierDelegate Protocol

The HTNotifierDelegate protocol allows you to respond to actions going on inside the notifier as well as provide runtime customizations.

All of the delegate methods in the HTNotifierDelegate protocol are documented in the HTNotifier header file. Here are just a few of those methods:

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
      
      #pragma mark -
      #pragma mark HTNotifierDelegate
      /*
        These are only a few of the delegate methods you can implement
        The rest are documented in HTNotifierDelegate.h
        All of the delegate methods are optional
      */
      - (void)notifierWillDisplayAlert {
        [gameController pause];
      }
      - (void)notifierDidCloseAlert {
        [gameController resume];
      }
      - (NSString *)titleForNoticeAlert {
        return @"Oh Noes!";
      }
      - (NSString *)bodyForNoticeAlert {
        return [NSString stringWithFormat:
                @"%@ has detected unreported crashes, would you like to send a report to the developer?",
                HTNotifierBundleName];
      }
      
    @end

Set the delegate on the notifier object in your `application:didFinishLaunchingWithOptions:`

    [[HTNotifier sharedNotifier] setDelegate:self];

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
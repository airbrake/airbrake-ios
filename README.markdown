#About

The Hoptoad iOS Notifier is designed to give developers instant notification of problems that occur in their apps. With just a few lines of code and a few extra files in your project, your app will automatically phone home whenever a crash or exception is encountered. These reports go straight to Hoptoad ([http://hoptoadapp.com](http://hoptoadapp.com)) where you can see information like backtrace, device type, app version, and more.

To see a screencast visit [http://guicocoa.com/hoptoad#screencast](http://guicocoa.com/hoptoad#screencast)

If you have questions or need support please visit the support page at [http://help.hoptoadapp.com/discussions/ios-notifier](http://help.hoptoadapp.com/discussions/ios-notifier)

##Notes

The notifier handles all unhanded exceptions, and a select list of Unix signals:

- SIGABRT
- SIGBUS
- SIGFPE
- SIGILL
- SIGSEGV
- SIGTRAP

The HTNotifier class is the primary class you will interact with while using the notifier. All of its methods and properties, along with the HTNotifierDelegate protocol are documented in HTNotifier.h. Please read through the header file for a complete reference of the library. For quick reference and examples, read the sections below.

In order for the call stack to be properly symbolicated at the time of a crash, applications built with the notifier should not be stripped of their symbol information at compile time. If these settings are not set as  recommended, frames from your binary will be displayed as hex return addresses instead of readable strings. These hex return addresses can be symbolicated using `atos`. More information about symbolication and these build settings can be found at [http://developer.apple.com/tools/xcode/symbolizingcrashdumps.html](http://developer.apple.com/tools/xcode/symbolizingcrashdumps.html) Here are the settings that control code stripping:

- Deployment Postprocessing: Off
- Strip Debug Symbols During Copy: Off
- Strip Linked Product: Off

If you add the following build script to your target, the notifier will report the git hash and automatic build version (based on git commit count) with each notice.  [https://github.com/guicocoa/xcode-git-cfbundleversion](https://github.com/guicocoa/xcode-git-cfbundleversion)

#Installation

1. Drag the hoptoadnotifier and kissxml folders to your project
    
    - make sure "Copy Items" and "Create Groups" are selected
    
    - If you are already using kissxml, you don't need to include it again

2. Add SystemConfiguration.framework and libxml2.dylib to your project

3. Add the path /usr/include/libxml2 to Header Search Paths in your project's build settings
  
    - make sure you add it under "All Configurations"
    
#Running The Notifier

To run the notifier you only need to complete two steps. First, import the HTNotifier header file in your app delegate

    #import "HTNotifier.h"
    
Next, call the main notifier method at the very beginning of your `application:didFinishLaunchingWithOptions:`

    [HTNotifier startNotifierWithAPIKey:<# api key #>
                        environmentName:<# environment #>];

The API key argument expects your Hoptoad project API key. The environment name you provide will be used to categorize received crash reports in the Hoptoad web interface. The notifier provides several factory environment names that you are free to use.

  - `HTNotifierDevelopmentEnvironment`
  - `HTNotifierAdHocEnvironment`
  - `HTNotifierAppStoreEnvironment`
  - `HTNotifierReleaseEnvironment`

#Testing

To test that the notifier is working inside your application, a simple test method is provided. This method creates a notice with all of the parameters filled out as if a method, `crash`, was called on the shared HTNotifier object. That notice will be picked up by the notifier and reported just like an actual crash. Add this code to your `application:didFinishLaunchingWithOptions:` to test the notifier:

     [[HTNotifier sharedNotifier] writeTestNotice];

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
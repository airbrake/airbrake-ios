#About

The Hoptoad iOS Notifier is designed to give developers instant notification of problems that occur in their apps. With just a few lines of code and a few extra files in your project, your app will automatically phone home whenever a crash or exception is encountered. These reports go straight to Hoptoad (http://hoptoadapp.com) where you can see information like backtrace, device type, app version, and more!

##Notes

The notifier handles all unhanded exceptions, and a select list of Unix signals:

- SIGABRT
- SIGBUS
- SIGFPE
- SIGILL
- SIGSEGV
- SIGTRAP

The HTNotifier class is the primary class you will interact with while using the notifier. All of its methods and properties, along with the HTNotifierDelegate protocol are documented in HTNotifier.h. Please read through the header file for a complete reference of the library. For quick reference and examples, read the sections below.

To see a screencast visit [http://guicocoa.com/hoptoad#screencast](http://guicocoa.com/hoptoad#screencast)

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
    
Next, call the main notifier method right at the beginning of your `application:didFinishLaunchingWithOptions:`

    [HTNotifier startNotifierWithAPIKey:@"<# api key #>"
                        environmentName:@"<# environment #>"];

The API key argument expects your Hoptoad project API key. The environment name you provide will be used to categorize received crash reports in the Hoptoad web interface. You can substitute several useful values into this parameter as a formatted string like:

  - `HTNotifierBundleVersion`
  - `HTNotifierBuildDate`
  - `HTNotifierBuildTime`

For convenience, the notifier provides you a few factory environment names that should cover most scenarios. They are:

  - `HTNotifierDevelopmentEnvironment` - this string includes the build date and time
  - `HTNotifierAdHocEnvironment` - this string includes the build date
  - `HTNotifierAppStoreEnvironment` - this string includes the bundle version

#Testing

To test that the notifier is working inside your application, a simple test method is provided. This method creates a notice with all of the paremeters filled out as if a method, `crash`, was called on the shared HTNotifier object. That notice will be picked up by the notifier and reported just like an actual crash. Add this code to your `application:didFinishLaunchingWithOptions:` to test the notifier:

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
        The rest are documented in HTNotifier.h
        All of the delegate methods are optional
      */
      - (UIViewController *)rootViewControllerForNotice {
        return self.rootViewController;
      }
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

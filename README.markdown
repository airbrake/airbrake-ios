#Introduction

The Hoptoad iOS Notifier is designed to give developers instant notification of problems that occur in their apps. With just a few lines of code and a few extra files in your project, your app will automatically phone home whenever a crash or exception is encountered. These reports go straight to Hoptoad (http://hoptoadapp.com) where you can see information like backtrace, device type, app version, and more!

##Note

The HTNotifier class is the primary class you will interact with while using the notifier. All of its methods and properties, along with the HTNotifierDelegate protocol are documented in HTNotifier.h. For quick reference and examples, read the sections below.

#Installation

1. Drag the hoptoadnotifier and kissxml folders to your project
    
    - make sure "Copy Items" and "Create Groups" are selected
    
    - If you are already using kissxml, you don't need to include it again

2. Add SystemConfiguration.framework and libxml2.dylib to your project

3. Add the path /usr/include/libxml2 to Header Search Paths in your project's build settings
  
    - make sure you add it under "All Configurations"

4. Import HTNotifier.h in your app delegate header file

    `#import "HTNotifier.h"`

5. Add the following code to the very beginning of your application:didFinishLaunchingWithOptions:
    - code executed before this line will not be monitored for exceptions and crashes

    `[HTNotifier sharedNotifierWithAPIKey:@"<# api key #>" environmentName:@"<# environment #>"];`

#Testing

To test that the notifier is working inside your application, a simple test method is provided. Add the following code to the very beginning of your application:didFinishLaunchingWithOptions:
    
    HTNotifier *notifier = [HTNotifier sharedNotifierWithAPIKey:@"<# api key #>" environmentName:@"<# environment #>"];
    [notifier writeTestNotice];

That notice will be picked up by the notifier and reported just like a normal notice.

#Implementing the HTNotifierDelegate Protocol

The HTNotifierDelegate protocol allows you to respond to actions going on inside the notifier as well as provide runtime customizations

The -notifierWillDisplayAlert and -notifierDidDismissAlert methods let your application respond to alert actions. These methods should be handled just like -applicationWillResignActive: and -applicationDidBecomeActive:.

These methods are documented in the HTNotifierDelegate header file.

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
        return @"$BUNDLE has detected unreported crashes, would you like to send a report to the developer?";
      }
      
    @end

Set the delegate on the notifier object at the beginning of your application:didFinishLaunchingWithOptions:

    HTNotifier *notifier = [HTNotifier sharedNotifierWithAPIKey:@"<# api key #>" environmentName:@"<# environment #>"];
    [notifier setDelegate:self];

#Set Properties on the Notifier

Properties can be set on the notifier allowing you to modify some of its behaviors at run time. Any properties that can be set are defined in the HTNotifier header file.

MyAppDelegate.m

    #import HTNotifier.h

At the beginning of your application:didFinishLaunchingWithOptions:

    HTNotifier *notifier = [HTNotifier sharedNotifierWithAPIKey:@"<# api key #>" environmentName:@"<# environment #>"];
    [notifier setUseSSL:YES];
    [notifier setLogCrashesInSimulator:YES];

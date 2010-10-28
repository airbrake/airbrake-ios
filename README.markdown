#Introduction

The Hoptoad iOS Notifier is designed to give developers instant notification of problems that occur in their apps. With just a few lines of code and a few extra files in your project, your app will automatically phone home whenever a crash or exception is encountered. These reports go straight to Hoptoad (http://hoptoadapp.com) where you can see information like backtrace, device type, app version, and more!

##Note

The HTNotifier class is the primary class you will interact with while using the notifier. All of its methods and properties, along with the HTNotifierDelegate protocol are documented in HTNotifier.h. Please read through the header file for a complete reference of the library. For quick reference and examples, read the sections below.

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

    `[HTNotifier startNotifierWithAPIKey:@"<# api key #>"
                         environmentName:@"<# environment #>"];`

#Testing

To test that the notifier is working inside your application, a simple test method is provided. This method creates a notice named [HTNotice selectorThatDoesNotExist]; with a sample backtrace and other appropriate fields. Add the following code to the very beginning of your application:didFinishLaunchingWithOptions:

    [HTNotifier startNotifierWithAPIKey:@"<# api key #>"
                        environmentName:@"<# environment #>"];
    [[HTNotifier sharedNotifier] writeTestNotice];
    
That notice will be picked up by the notifier and reported just like a normal notice.

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

Set the delegate on the notifier object at the beginning of your application:didFinishLaunchingWithOptions:

    [HTNotifier startNotifierWithAPIKey:@"<# api key #>"
                        environmentName:@"<# environment #>"];
    [[HTNotifier sharedNotifier] setDelegate:self];

#Set Properties on the Notifier

Properties can be set on the notifier allowing you to modify some of its behaviors at run time. Any properties that can be set are defined in the HTNotifier header file.

MyAppDelegate.m

    #import HTNotifier.h

At the beginning of your application:didFinishLaunchingWithOptions:

    [HTNotifier startNotifierWithAPIKey:@"<# api key #>"
                        environmentName:@"<# environment #>"];
    [[HTNotifier sharedNotifier] setUseSSL:YES];
    [[HTNotifier sharedNotifier] setLogCrashesInSimulator:NO];

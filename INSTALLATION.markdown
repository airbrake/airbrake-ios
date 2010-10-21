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
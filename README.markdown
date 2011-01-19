<h1 id="about">About</h1>

<p>The Hoptoad iOS Notifier is designed to give developers instant notification of problems that occur
in their apps. With just a few lines of code and a few extra files in your project, your app will
automatically phone home whenever a crash or exception is encountered. These reports go straight to
Hoptoad (<a href="http://hoptoadapp.com">http://hoptoadapp.com</a>) where you can see information like backtrace,
device type, app version, and more.</p>

<p>To see a screencast visit <a href="http://guicocoa.com/hoptoad#screencast">http://guicocoa.com/hoptoad#screencast</a></p>

<p>If you have questions or need support please visit the support page at <a href="http://help.hoptoadapp.com/discussions/ios-notifier">http://help.hoptoadapp.com/discussions/ios-notifier</a></p>

<h2 id="notes">Notes</h2>

<p>The notifier handles all unhanded exceptions, and a select list of Unix signals:</p>

<ul>
<li>SIGABRT</li>
<li>SIGBUS</li>
<li>SIGFPE</li>
<li>SIGILL</li>
<li>SIGSEGV</li>
<li>SIGTRAP</li>
</ul>

<p>The HTNotifier class is the primary class you will interact with while using the notifier. All of its
methods and properties, along with the HTNotifierDelegate protocol are documented in HTNotifier.h.
Please read through the header file for a complete reference of the library. For quick reference and
examples, read the sections below.</p>

<h1 id="installation">Installation</h1>

<ol>
<li><p>Drag the hoptoadnotifier and kissxml folders to your project</p>

<ul>
<li><p>make sure &#8220;Copy Items&#8221; and &#8220;Create Groups&#8221; are selected</p></li>
<li><p>If you are already using kissxml, you don&#8217;t need to include it again</p></li>
</ul></li>
<li><p>Add SystemConfiguration.framework and libxml2.dylib to your project</p></li>
<li><p>Add the path /usr/include/libxml2 to Header Search Paths in your project&#8217;s build settings</p>

<ul>
<li>make sure you add it under &#8220;All Configurations&#8221;</li>
</ul></li>
</ol>

<h1 id="running_the_notifier">Running The Notifier</h1>

<p>To run the notifier you only need to complete two steps. First, import the HTNotifier header file in
your app delegate</p>

<pre><code>#import "HTNotifier.h"
</code></pre>

<p>Next, call the main notifier method at the very beginning of your <code>application:didFinishLaunchingWithOptions:</code></p>

<pre><code>[HTNotifier startNotifierWithAPIKey:&lt;# api key #&gt;
                    environmentName:&lt;# environment #&gt;];
</code></pre>

<p>The API key argument expects your Hoptoad project API key. The environment name you provide will be
used to categorize received crash reports in the Hoptoad web interface. The notifier provides several factory environment names that you are free to use.</p>

<ul>
<li><code>HTNotifierDevelopmentEnvironment</code></li>
<li><code>HTNotifierAdHocEnvironment</code></li>
<li><code>HTNotifierAppStoreEnvironment</code></li>
<li><code>HTNotifierReleaseEnvironment</code></li>
</ul>

<h1 id="testing">Testing</h1>

<p>To test that the notifier is working inside your application, a simple test method is provided. This
method creates a notice with all of the parameters filled out as if a method, <code>crash</code>, was called on
the shared HTNotifier object. That notice will be picked up by the notifier and reported just like an
actual crash. Add this code to your <code>application:didFinishLaunchingWithOptions:</code> to test the notifier:</p>

<pre><code> [[HTNotifier sharedNotifier] writeTestNotice];
</code></pre>

<h1 id="implementing_the_htnotifierdelegate_protocol">Implementing the HTNotifierDelegate Protocol</h1>

<p>The HTNotifierDelegate protocol allows you to respond to actions going on inside the notifier as well
as provide runtime customizations.</p>

<p>All of the delegate methods in the HTNotifierDelegate protocol are documented in the HTNotifier header
file. Here are just a few of those methods:</p>

<p>MyAppDelegate.h</p>

<pre><code>#import HTNotifier.h

@interface MyAppDelegate : NSObject &lt;UIApplicationDelegate, HTNotifierDelegate&gt; {
  // your ivars
}

// your properties and methods

@end
</code></pre>

<p>MyAppDelegate.m</p>

<pre><code>@implementation MyAppDelegate

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
</code></pre>

<p>Set the delegate on the notifier object in your <code>application:didFinishLaunchingWithOptions:</code></p>

<pre><code>[[HTNotifier sharedNotifier] setDelegate:self];
</code></pre>

<h1 id="contributors">Contributors</h1>

<ul>
<li><a href="http://guicocoa.com">Caleb Davenport</a></li>
<li><a href="http://twoguys.us">Marshall Huss</a></li>
<li><a href="http://twitter.com/bebroll">Benjamin Broll</a></li>
<li>Sergei Winitzki</li>
<li>Irina Anastasiu</li>
</ul>

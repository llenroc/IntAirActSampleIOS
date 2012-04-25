#import "IAAppDelegate.h"

#import <CocoaHTTPServer/HTTPLogging.h>
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <RestKit/RestKit.h>

#import "IAInteract.h"
#import "IAImageClient.h"
#import "IAImageServer.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAAppDelegate ()

@property (nonatomic, strong) IAInteract * interact;
@property (nonatomic, strong) IAImageServer * imageServer;

@end

@implementation IAAppDelegate

@synthesize window = _window;

@synthesize interact = _interact;
@synthesize imageServer = _imageServer;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure logging framework to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // Configure RestKit logging framework
    //RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    
    // setup and start Interact
    self.interact = [IAInteract new];
    [IAImageClient setupMapping:self.interact];
    self.imageServer = [[IAImageServer alloc] initWithInteract:self.interact];
    
    NSError * error;
    
    if(![self.interact start:&error]) {
        DDLogError(@"%@: Error starting Interact: %@", THIS_FILE, error);
    }
    
    UINavigationController * navigationController = (UINavigationController*) self.window.rootViewController;
    
    // the imageServer requires the navigationController to open up a new view on a display action
    self.imageServer.navigationController = navigationController;
    
    // set interact property of the first active ViewController
    UIViewController * firstViewController = [[navigationController viewControllers] objectAtIndex:0];
    if([firstViewController respondsToSelector:@selector(setInteract:)]) {
        [firstViewController performSelector:@selector(setInteract:) withObject:self.interact];
    }
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    [self.interact stop];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    if(![self.interact isRunning]) {
        NSError * err;
        if(![self.interact start:&err]) {
            DDLogError(@"%@: Error starting Interact: %@", THIS_FILE, err);
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [self.interact stop];
}

@end

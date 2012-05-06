#import "IAAppDelegate.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>
#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IAImage.h"
#import "IAImageClient.h"
#import "IAImageTableViewController.h"
#import "IAImageViewController.h"
#import "IAServer.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAAppDelegate ()

@property (nonatomic, strong) IAIntAirAct * intAirAct;
@property (nonatomic, weak) UINavigationController * navigationController;
@property (nonatomic, strong) IAServer * server;

@end

@implementation IAAppDelegate

@synthesize window;

@synthesize intAirAct;
@synthesize navigationController;
@synthesize server;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure logging framework to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // Configure RestKit logging framework
    //RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    
    // create, setup and start IntAirAct
    self.intAirAct = [IAIntAirAct new];
    [self.intAirAct addMappingForClass:[IAImage class] withKeypath:@"images" withAttributes:@"identifier", nil];
    [self.intAirAct.router routeClass:[IAImage class] toResourcePath:@"/image/:identifier"];
    
    self.navigationController = (UINavigationController *) self.window.rootViewController;
    UIViewController * firstViewController = [[self.navigationController viewControllers] objectAtIndex:0];
    if([firstViewController respondsToSelector:@selector(setIntAirAct:)]) {
        [firstViewController performSelector:@selector(setIntAirAct:) withObject:self.intAirAct];
    }

    self.server = [[IAServer alloc] initWithIntAirAct:self.intAirAct];
    self.server.navigationController = self.navigationController;
    
    NSError * error;
    if(![self.intAirAct start:&error]) {
        DDLogError(@"%@: Error starting IntAirAct: %@", THIS_FILE, error);
        return NO;
    }
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end

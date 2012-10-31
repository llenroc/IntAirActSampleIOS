#import "IAAppDelegate.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>
#import <IntAirAct/IARoutingHTTPServerAdapter.h>
#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>
#import <ServiceDiscovery/ServiceDiscovery.h>

#import "IAImage.h"
#import "IAImageClient.h"
#import "IAServer.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAAppDelegate ()

@property (nonatomic, strong) IAIntAirAct * intAirAct;
@property (nonatomic, weak) UINavigationController * navigationController;
@property (nonatomic, strong) IAServer * server;

@end

@implementation IAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure logging framework to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if(getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")) {
        DDLogWarn(@"NSZombieEnabled/NSAutoreleaseFreedObjectCheckEnabled enabled!");
    }
    
    // Configure RestKit logging framework
    //RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    
    RoutingHTTPServer * routingHTTPServer = [RoutingHTTPServer new];
    IARoutingHTTPServerAdapter * routingHTTPServerAdapter = [[IARoutingHTTPServerAdapter alloc] initWithRoutingHTTPServer:routingHTTPServer];
    SDServiceDiscovery * serviceDiscovery = [SDServiceDiscovery new];
    
    // create, setup and start IntAirAct
    self.intAirAct = [[IAIntAirAct alloc] initWithServer:routingHTTPServerAdapter andServiceDiscovery:serviceDiscovery];

#if DEBUG
    [serviceDiscovery setLogLevel:SD_LOG_LEVEL_VERBOSE];
    self.intAirAct.port = 12345;
#endif

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

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    NSError * error;
    if(![self.intAirAct start:&error]) {
        DDLogError(@"%@: Error starting IntAirAct: %@", THIS_FILE, error);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self setControlsHidden:NO animated:NO];
    [self.intAirAct stop];
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    [self.intAirAct stop];
}

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated {
    // Status Bar
    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
    
    // Get status bar height if visible
    CGFloat statusBarHeight = 0;
    if (![UIApplication sharedApplication].statusBarHidden) {
        CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
        statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
    }
    
    // Set navigation bar frame
    CGRect navBarFrame = self.navigationController.navigationBar.frame;
    navBarFrame.origin.y = statusBarHeight;
    self.navigationController.navigationBar.frame = navBarFrame;
	
    CGFloat alpha = hidden ? 0 : 1;
	[self.navigationController.navigationBar setAlpha:alpha];
}

@end

#import "IAAppDelegate.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>
#import <IntAirAct/IARoutingHTTPServerAdapter.h>
#import <IntAirAct/IANSURLAdapter.h>
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
    IANSURLAdapter * nsURLAdapter = [IANSURLAdapter new];
    
    // create, setup and start IntAirAct
    self.intAirAct = [[IAIntAirAct alloc] initWithServer:routingHTTPServerAdapter client:nsURLAdapter andServiceDiscovery:serviceDiscovery];

    // necessary to set the origin on incoming requests
    routingHTTPServerAdapter.intAirAct = self.intAirAct;

#if DEBUG
    [serviceDiscovery setLogLevel:SD_LOG_LEVEL_VERBOSE];
    self.intAirAct.port = 12345;
#endif

    // inject intairact into first viewcontroller
    self.navigationController = (UINavigationController *) self.window.rootViewController;
    UIViewController * firstViewController = [[self.navigationController viewControllers] objectAtIndex:0];
    if([firstViewController respondsToSelector:@selector(setIntAirAct:)]) {
        [firstViewController performSelector:@selector(setIntAirAct:) withObject:self.intAirAct];
    }

    // moved all server code into one class
    self.server = [IAServer serverWithIntAirAct:self.intAirAct navigationController:self.navigationController];

    // test code that sends a request to self as soon as it is discovered
    [self.intAirAct addHandlerForDeviceFound:^(IADevice *device, BOOL ownDevice) {
        if (ownDevice) {
            IARequest * request = [IARequest requestWithRoute:[IARoute routeWithAction:@"PUT" resource:@"/views/image"] metadata:nil parameters:nil origin:self.intAirAct.ownDevice body:[@"http://ase.cpsc.ucalgary.ca/uploads/images/GalleryThumbs/58-7.jpg" dataUsingEncoding:NSUTF8StringEncoding]];
            [self.intAirAct sendRequest:request toDevice:self.intAirAct.ownDevice withHandler:^(IAResponse *response, NSError * error) {
                DDLogVerbose(@"Received response: %@", response);
            }];
        }
    }];
    
    NSError * error;
    if(![self.intAirAct start:&error]) {
        DDLogError(@"%@: Error starting IntAirAct: %@", THIS_FILE, error);
        return NO;
    }
    
    // Override point for customization after application launch.
    return YES;
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSError * error;
    if(![self.intAirAct start:&error]) {
        DDLogError(@"%@: Error starting IntAirAct: %@", THIS_FILE, error);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self setControlsHidden:NO animated:NO];
    [self.intAirAct stop];
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self.intAirAct stop];
}

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

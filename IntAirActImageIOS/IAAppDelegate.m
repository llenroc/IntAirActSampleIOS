#import "IAAppDelegate.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

#import "IAImage.h"
#import "IAImageServer.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAAppDelegate ()

@property (nonatomic, strong) IAIntAirAct * intAirAct;
@property (nonatomic, weak) UINavigationController * navigationController;
@property (nonatomic, strong) IAImageServer * server;

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
    
    // create, setup and start IntAirAct
    self.intAirAct = [IAIntAirAct new];

#if DEBUG
    self.intAirAct.port = 12345;
#endif

    // inject intairact into first viewcontroller
    self.navigationController = (UINavigationController *) self.window.rootViewController;
    UIViewController * firstViewController = [[self.navigationController viewControllers] objectAtIndex:0];
    if([firstViewController respondsToSelector:@selector(setIntAirAct:)]) {
        [firstViewController performSelector:@selector(setIntAirAct:) withObject:self.intAirAct];
    }

    // moved all server code into one class
    self.server = [IAImageServer serverWithIntAirAct:self.intAirAct navigationController:self.navigationController];
    
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
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
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

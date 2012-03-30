//
//  IAAppDelegate.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAAppDelegate.h"

#import "IAInteract.h"
#import "IAImageClient.h"
#import "IAImageServer.h"

@interface IAAppDelegate ()

@property (nonatomic, strong) IAInteract * interact;

@end

@implementation IAAppDelegate

@synthesize window = _window;

@synthesize interact = _interact;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure logging framework to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // Configure RestKit logging framework
    //RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    
    // setup and start Interact
    self.interact = [IAInteract new];
    [IAImageClient setupMapping:_interact];
    IAImageServer * imageServer = [[IAImageServer alloc] initWithInteract:_interact];
    [_interact registerServer:imageServer];
    
    NSError * error;
    if(![self.interact start:&error]) {
        DDLogError(@"Error starting Interact: %@", error);
    }
    
    // set interact property of the first active ViewController
    UINavigationController * navigationController = (UINavigationController*) self.window.rootViewController;
    imageServer.navigationController = navigationController;
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
    [self.interact start:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end

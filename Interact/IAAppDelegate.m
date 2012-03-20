//
//  IAAppDelegate.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAAppDelegate.h"
#import "IAImageServerMapper.h"

@interface IAAppDelegate() {
    IAImageServerMapper * imageServerMapper;
}

@end

@implementation IAAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure our logging framework.
	// To keep things simple and fast, we're just going to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    //RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);

    RKObjectMapping* imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
    imageMapping.rootKeyPath = @"images";

    [imageMapping mapKeyPath:@"id" toAttribute:@"identifier"];
    [imageMapping mapKeyPath:@"name" toAttribute:@"name"];
    [imageMapping mapKeyPath:@"src" toAttribute:@"location"];
    
    RKObjectMapping* imageSerialization = [imageMapping inverseMapping];
    imageSerialization.rootKeyPath = @"images";
    
    RKObjectMappingProvider * objectMappingProvider = [[RKObjectMappingProvider alloc] init];    
    [objectMappingProvider setMapping:imageMapping forKeyPath:@"images"];
    [objectMappingProvider setSerializationMapping:imageSerialization forClass:[IAImage class]];

    imageServerMapper = [[IAImageServerMapper alloc] initWithObjectMappingProvider:objectMappingProvider];
    imageServerMapper.imageServer = [[IAImageServer alloc] init];
    [imageServerMapper startServer];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

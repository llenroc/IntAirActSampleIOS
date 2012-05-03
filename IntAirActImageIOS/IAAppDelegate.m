#import "IAAppDelegate.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>
#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IAImage.h"
#import "IAImages.h"
#import "IAImageClient.h"
#import "IAImageTableViewController.h"
#import "IAImageViewController.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface IAAppDelegate ()

@property (nonatomic, strong) NSDictionary * idToImages;
@property (nonatomic, strong) NSArray * images;
@property (nonatomic, strong) IAIntAirAct * intAirAct;
@property (nonatomic, weak) UINavigationController * navigationController;

@end

@implementation IAAppDelegate

@synthesize window = _window;

@synthesize idToImages = _idToImages;
@synthesize images = _images;
@synthesize intAirAct = _intAirAct;
@synthesize navigationController = _navigationController;

+(ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary * library = nil;
    dispatch_once(&pred, ^{
        library = [ALAssetsLibrary new];
    });
    return library; 
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure logging framework to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // Configure RestKit logging framework
    //RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    
    // create, setup and start IntAirAct
    self.intAirAct = [IAIntAirAct new];
    [self setup];
    
    NSError * error;
    if(![self.intAirAct start:&error]) {
        DDLogError(@"%@: Error starting IntAirAct: %@", THIS_FILE, error);
        return NO;
    }
    
    self.navigationController = (UINavigationController*) self.window.rootViewController;
    
    // set intAirAct property of the first active ViewController
    UIViewController * firstViewController = [[self.navigationController viewControllers] objectAtIndex:0];
    if([firstViewController respondsToSelector:@selector(setIntAirAct:)]) {
        [firstViewController performSelector:@selector(setIntAirAct:) withObject:self.intAirAct];
    }
    
    // Override point for customization after application launch.
    return YES;
}

-(void)setup
{
    [self loadImages];
    
    // setup mappings for client and server side
    [self.intAirAct addMappingForClass:[IAImage class] withKeypath:@"images" withAttributes:@"identifier", nil];

    // This is a workaround for serializing arrays of images, see https://github.com/RestKit/RestKit/issues/398
    RKObjectMapping * imageSerialization = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    imageSerialization.rootKeyPath = @"images";
    [imageSerialization mapAttributes:@"identifier", nil];

    RKObjectMapping * imagesSerialization = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [imagesSerialization hasMany:@"images" withMapping:imageSerialization];
    [self.intAirAct.objectMappingProvider setSerializationMapping:imagesSerialization forClass:[IAImages class]];
    
    // setup routes
    [self.intAirAct.router routeClass:[IAImage class] toResourcePath:@"/image/:identifier"];
    
    [self.intAirAct.httpServer get:@"/images" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"GET /images");
        
        IAImages * images = [IAImages new];
        images.images = self.images;
        [response respondWith:images withIntAirAct:self.intAirAct];
    }];
    
    [self.intAirAct.httpServer get:@"/image/:id.jpg" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"GET /image/%@.jpg", [request param:@"id"]);
        
        NSNumber * number = [NSNumber numberWithInt:[[request param:@"id"] intValue]];
        NSData * data = [self imageAsData:number];
        if (!data) {
            DDLogError(@"An error ocurred.");
            response.statusCode = 500;
        } else {
            response.statusCode = 200;
            [response setHeader:@"Content-Type" value:@"image/jpeg"];
            [response respondWithData:data];
        }
    }];
    
    [self.intAirAct.httpServer put:@"/action/displayImage" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"PUT /action/displayImage");
        
        RKObjectMappingResult * result = [self.intAirAct deserializeObject:[request body]];
        if(!result && [[result asObject] isKindOfClass:[IAAction class]]) {
            DDLogError(@"Could not parse request body: %@", [request bodyAsString]);
            response.statusCode = 500;
        } else {
            response.statusCode = 201;
            IAAction * action = [result asObject];
            
            // Show image
            UIStoryboard * storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIMainStoryboardFile"] bundle: nil];
            
            UIViewController * rootViewController = [self.navigationController.viewControllers objectAtIndex:0];
            
            IAImageTableViewController * imageTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"ImageTableViewController"];
            imageTableViewController.intAirAct = self.intAirAct;
            imageTableViewController.device = [action.parameters objectForKey:@"device"];
            
            IAImageViewController * imageViewController = [storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
            imageViewController.intAirAct = self.intAirAct;
            imageViewController.image = [action.parameters objectForKey:@"image"];
            imageViewController.device = [action.parameters objectForKey:@"device"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController setViewControllers:[NSArray arrayWithObjects:rootViewController, imageTableViewController, imageViewController, nil] animated:YES];
            });
        }
    }];
    
    [self.intAirAct.httpServer put:@"/action/add" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"PUT /action/add");
        
        RKObjectMappingResult * result = [self.intAirAct deserializeObject:[request body]];
        if(!result && [[result asObject] isKindOfClass:[IAAction class]]) {
            DDLogError(@"Could not parse request body: %@", [request bodyAsString]);
            response.statusCode = 500;
        } else {
            response.statusCode = 201;
            IAAction * action = [result asObject];
            
            NSNumber * a = [action.parameters objectForKey:@"a"];
            NSNumber * b = [action.parameters objectForKey:@"b"];
            
            NSNumber * result = [NSNumber numberWithInt:([a intValue] + [b intValue])];
            
            IAAction * r = [IAAction new];
            r.parameters = [NSDictionary dictionaryWithKeysAndObjects:@"c", result, nil];
            
            [response respondWith:r withIntAirAct:self.intAirAct];
        }
    }];
}

-(void)loadImages
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    // collect the photos
    NSMutableArray * collector = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableDictionary * dictionary = [NSMutableDictionary new];
    ALAssetsLibrary * al = [[self class] defaultAssetsLibrary];
    
    __block int i = 1;
    [al enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
            if (asset) {
                NSString * prop = [asset valueForProperty:@"ALAssetPropertyType"];
                if(prop && [prop isEqualToString:@"ALAssetTypePhoto"]) {
                    ALAssetRepresentation * rep = [asset representationForUTI:@"public.jpeg"];
                    if (rep) {
                        IAImage * image = [IAImage new];
                        image.identifier = [NSNumber numberWithInt:i];
                        [collector addObject:image];
                        [dictionary setObject:asset forKey:image.identifier];
                        i++;
                    }
                }
            }  
        }];
        
        self.images = collector;
        self.idToImages = dictionary;
        DDLogVerbose(@"Loaded images");
    } failureBlock:^(NSError * error) {
        DDLogError(@"Couldn't load assets: %@", error);
    }];
    
}

-(NSData *)imageAsData:(NSNumber*)identifier
{
    ALAsset * ass = [self.idToImages objectForKey:identifier];
    
    int byteArraySize = ass.defaultRepresentation.size;
    
    DDLogVerbose(@"Size of the image: %i", byteArraySize);
    
    NSMutableData* rawData = [[NSMutableData alloc]initWithCapacity:byteArraySize];
    void* bufferPointer = [rawData mutableBytes];
    
    NSError* error=nil;
    [ass.defaultRepresentation getBytes:bufferPointer fromOffset:0 length:byteArraySize error:&error];
    if (error) {
        DDLogError(@"Couldn't copy bytes: %@",error);
    }
    
    rawData = [NSMutableData dataWithBytes:bufferPointer length:byteArraySize];
    
    return rawData;
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    [self.intAirAct stop];
    
    [self.navigationController popToRootViewControllerAnimated:NO];
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

    if(![self.intAirAct isRunning]) {
        [self loadImages];
        NSError * err;
        if(![self.intAirAct start:&err]) {
            DDLogError(@"%@: Error starting IntAirAct: %@", THIS_FILE, err);
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [self.intAirAct stop];
}

@end
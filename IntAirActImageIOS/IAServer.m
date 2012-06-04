#import "IAServer.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>

#import "IAImage.h"
#import "IAImageTableViewController.h"
#import "IAImageViewController.h"
#import "IAPhotoBrowser.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAServer ()

@property (nonatomic, strong) NSDictionary * idToImages;
@property (nonatomic, strong) NSArray * images;

@end

@implementation IAServer

@synthesize idToImages;
@synthesize images;

@synthesize intAirAct;
@synthesize navigationController;

+(ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary * library = nil;
    dispatch_once(&pred, ^{
        library = [ALAssetsLibrary new];
    });
    return library; 
}

-(id)initWithIntAirAct:(IAIntAirAct *)value
{
    self = [super init];
    if (self) {
        intAirAct = value;
        [self setup];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setup
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadImages)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [self.intAirAct addAction:@"displayImage" withSelector:@selector(displayImage:ofDevice:) andTarget:self];
    [self.intAirAct addAction:@"add" withSelector:@selector(add:to:) andTarget:self];
    
    [self.intAirAct.httpServer get:@"/images" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"GET /images");
        
        [response respondWith:self.images withIntAirAct:self.intAirAct];
    }];
    
    [self.intAirAct.httpServer get:@"/image/:id.jpg" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"GET /image/%@.jpg", [request param:@"id"]);
        
        NSData * data = [self imageAsData:[request param:@"id"]];
        if (!data) {
            DDLogError(@"An error ocurred.");
            response.statusCode = 500;
        } else {
            response.statusCode = 200;
            [response setHeader:@"Content-Type" value:@"image/jpeg"];
            [response respondWithData:data];
        }
    }];
    
    IACapability * imagesCap = [IACapability new];
    imagesCap.capability = @"GET /images";
    [self.intAirAct.capabilities addObject:imagesCap];
    
    IACapability * imageCap = [IACapability new];
    imageCap.capability = @"GET /images/:id.jpg";
    [self.intAirAct.capabilities addObject:imageCap];
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
        [group enumerateAssetsUsingBlock:^(ALAsset * asset, NSUInteger index, BOOL *stop) {
            if (asset) {
                NSString * prop = [asset valueForProperty:@"ALAssetPropertyType"];
                if(prop && [prop isEqualToString:@"ALAssetTypePhoto"]) {
                    ALAssetRepresentation * rep = [asset representationForUTI:@"public.jpeg"];
                    if (rep) {
                        IAImage * image = [IAImage new];
                        
                        NSArray * queryElements = [[rep.url query] componentsSeparatedByString:@"&"];
                        for (NSString * element in queryElements) {
                            NSArray * keyVal = [element componentsSeparatedByString:@"="];
                            if (keyVal.count > 0) {
                                NSString * variableKey = [keyVal objectAtIndex:0];
                                if([variableKey isEqualToString:@"id"]) {
                                    image.identifier = (keyVal.count == 2) ? [keyVal lastObject] : nil;
                                }
                            }
                        }
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
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    ALAsset * asset = [self.idToImages objectForKey:identifier];
    
    ALAssetRepresentation * representation = [asset representationForUTI:@"public.jpeg"];
    
    UIImage * image = [UIImage imageWithCGImage:representation.fullScreenImage];
    NSData * data = UIImageJPEGRepresentation(image, 0.8);
    
    return data;
}

-(NSNumber *)add:(NSNumber *)a to:(NSNumber *) b
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    return [NSNumber numberWithInt:([a intValue] + [b intValue])];
}

-(void)displayImage:(IAImage *)image ofDevice:(IADevice *)device
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    UIViewController * rootViewController = [self.navigationController.viewControllers objectAtIndex:0];
    
    IAPhotoBrowser * browser = [IAPhotoBrowser new];
    browser.intAirAct = self.intAirAct;
    browser.device = device;
    browser.image = image;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:rootViewController, browser, nil] animated:YES];
    });
}

@end

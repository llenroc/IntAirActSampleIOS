#import "IAServer.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>

#import "IAImage.h"
#import "IAImageTableViewController.h"
#import "IAImageViewController.h"

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
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
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

-(NSNumber *)add:(NSNumber *)a to:(NSNumber *) b
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    return [NSNumber numberWithInt:([a intValue] + [b intValue])];
}

-(void)displayImage:(IAImage *)image ofDevice:(IADevice *)device
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIMainStoryboardFile"] bundle: nil];
    
    UIViewController * rootViewController = [self.navigationController.viewControllers objectAtIndex:0];
    
    IAImageTableViewController * imageTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"ImageTableViewController"];
    imageTableViewController.intAirAct = self.intAirAct;
    imageTableViewController.device = device;
    
    IAImageViewController * imageViewController = [storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
    imageViewController.intAirAct = self.intAirAct;
    imageViewController.image = image;
    imageViewController.device = device;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:rootViewController, imageTableViewController, imageViewController, nil] animated:YES];
    });
}

@end
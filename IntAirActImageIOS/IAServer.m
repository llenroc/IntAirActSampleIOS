#import "IAServer.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>

#import "IAImage.h"
#import "IAPhotoBrowser.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAServer ()

@property (nonatomic, strong) NSDictionary * idToImages;
@property (nonatomic, strong) NSArray * images;
@property (nonatomic, weak) IAIntAirAct * intAirAct;
@property (nonatomic, weak) UINavigationController * navigationController;

@end

@implementation IAServer

+(ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary * library = nil;
    dispatch_once(&pred, ^{
        library = [ALAssetsLibrary new];
    });
    return library; 
}

+(IAServer *)serverWithIntAirAct:(IAIntAirAct *)intAirAct navigationController:(UINavigationController *)navigationController
{
    IAServer * server = [IAServer new];
    server.intAirAct = intAirAct;
    server.navigationController = navigationController;
    [server setup];
    return server;
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

    [self.intAirAct route:[IARoute routeWithAction:@"PUT" resource:@"/views/image"] withHandler:^(IARequest *request, IAResponse *response) {
        DDLogVerbose(@"PUT /views/image: %@", request);

        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

        IAPhotoBrowser * browser = [IAPhotoBrowser new];
        browser.intAirAct = self.intAirAct;
        browser.imageURLs = @[request.bodyAsString];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:NO];
            [self.navigationController pushViewController:browser animated:YES];
        });
    }];

    [self.intAirAct route:[IARoute routeWithAction:@"GET" resource:@"/images"] withHandler:^(IARequest *request, IAResponse *response) {
        DDLogVerbose(@"GET /images");
        [response respondWith:self.images withIntAirAct:self.intAirAct];
    }];
    
    [self.intAirAct route:[IARoute routeWithAction:@"GET" resource:@"/image/:id"] withHandler:^(IARequest *request, IAResponse *response) {
        DDLogVerbose(@"GET /image/%@.jpg", request.parameters[@"id"]);
        
        NSData * data = [self imageAsData: request.parameters[@"id"]];
        if (!data) {
            DDLogError(@"An error ocurred.");
            response.statusCode = @500;
        } else {
            response.statusCode = @200;
            response.metadata[@"Content-Type"] = @"image/jpeg";
            response.body = data;
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

@end

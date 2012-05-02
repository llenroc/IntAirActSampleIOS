#import "IAImageServer.h"

#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IAAction.h>
#import <IntAirAct/IAIntAirAct.h>
#import <IntAirAct/IARouteRequest+BodyAsString.h>
#import <IntAirAct/IARouteResponse+Serializer.h>
#import <RestKit/RestKit.h>

#import "IAImageProvider.h"
#import "IAImages.h"
#import "IAImageViewController.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAImageServer ()

@property (nonatomic, strong) IAIntAirAct * intAirAct;
@property (nonatomic, strong) IAImageProvider * imageProvider;

@end

@implementation IAImageServer

@synthesize navigationController = _navigationController;

@synthesize intAirAct = _intAirAct;
@synthesize imageProvider = _imageProvider;

-(id)initWithIntAirAct:(IAIntAirAct *)intAirAct
{
    self = [super init];
    if (self) {
        self.intAirAct = intAirAct;
        self.imageProvider = [IAImageProvider new];
        [self registerServer:intAirAct.httpServer];
    }
    return self;
}

-(void)registerServer:(RoutingHTTPServer *)app {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [app get:@"/images" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"GET /images");

        IAImages * images = [IAImages new];
        images.images = self.imageProvider.images;
        [response respondWith:images withIntAirAct:self.intAirAct];
    }];
    
    [app get:@"/image/:id.jpg" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"GET /image/%@.jpg", [request param:@"id"]);
        
        NSNumber * number = [NSNumber numberWithInt:[[request param:@"id"] intValue]];
        NSData * data = [self.imageProvider imageAsData:number];
        if (!data) {
            DDLogError(@"An error ocurred.");
            response.statusCode = 500;
        } else {
            response.statusCode = 200;
            [response setHeader:@"Content-Type" value:@"image/jpeg"];
            [response respondWithData:data];
        }
    }];
    
    [app put:@"/action/displayImage" withBlock:^(RouteRequest * request, RouteResponse * response) {
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
            IAImageViewController * t = [storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
            t.intAirAct = self.intAirAct;
            t.image = [action.parameters objectForKey:@"image"];
            t.device =[action.parameters objectForKey:@"device"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:t animated:YES];
            });
        }
    }];
}

@end

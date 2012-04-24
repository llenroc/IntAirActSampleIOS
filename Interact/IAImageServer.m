#import "IAImageServer.h"

#import <RestKit/RestKit.h>

#import "IAAction.h"
#import "IAImageProvider.h"
#import "IAImages.h"
#import "IAImageViewController.h"
#import "IAInteract.h"
#import "RouteRequest+BodyAsString.h"
#import "RouteResponse+Serializer.h"

@interface IAImageServer ()

@property (nonatomic, strong) IAInteract * interact;
@property (nonatomic, strong) IAImageProvider * imageProvider;

@end

@implementation IAImageServer

@synthesize navigationController = _navigationController;

@synthesize interact = _interact;
@synthesize imageProvider = _imageProvider;

-(id)initWithInteract:(IAInteract *)interact
{
    self = [super init];
    if (self) {
        self.interact = interact;
        self.imageProvider = [IAImageProvider new];
        [self registerServer:interact.httpServer];
    }
    return self;
}

-(void)registerServer:(RoutingHTTPServer *)app {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [app setDefaultHeader:@"Content-Type" value:RKMIMETypeJSON];
    
    [app get:@"/images" withBlock:^(RouteRequest * request, RouteResponse * response) {
        DDLogVerbose(@"GET /images");

        IAImages * images = [IAImages new];
        images.images = self.imageProvider.images;
        [response respondWith:images withInteract:self.interact];
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
        
        RKObjectMappingResult * result = [self.interact deserializeObject:[request body]];
        DDLogVerbose(@"Mapping result as Object: %@", [result asObject]);
        if(!result && [[result asObject] isKindOfClass:[IAAction class]]) {
            DDLogError(@"Could not parse request body: %@", [request bodyAsString]);
            response.statusCode = 500;
        } else {
            response.statusCode = 201;
            IAAction * action = [result asObject];
            DDLogVerbose(@"%@", action);
            
            // Show image
            UIStoryboard * storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIMainStoryboardFile"] bundle: nil];
            IAImageViewController * t = [storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
            t.interact = self.interact;
            t.image = [action.parameters objectForKey:@"image"];
            t.device =[action.parameters objectForKey:@"device"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:t animated:YES];
            });
        }
    }];
}

@end

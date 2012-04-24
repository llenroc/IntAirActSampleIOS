#import <Foundation/Foundation.h>

@class RKObjectManager;
@class RKObjectMappingProvider;
@class RKObjectMappingResult;
@class RKObjectRouter;
@class RKObjectSerializer;
@class RoutingHTTPServer;

@class IADevice;
@class IALocator;

@interface IAInteract : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, strong) RoutingHTTPServer * httpServer;
@property (nonatomic, strong) RKObjectMappingProvider * objectMappingProvider;
@property (nonatomic, strong) RKObjectRouter * router;

-(BOOL)start:(NSError **)errPtr;
-(void)stop;
-(RKObjectManager *)objectManagerForDevice:(IADevice *)device;
-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager;
-(RKObjectSerializer *)serializerForObject:(id)object;
-(NSArray *)devices;
-(RKObjectMappingResult *)deserializeObject:(NSData *)data;
-(RKObjectMappingResult *)deserializeDictionary:(NSDictionary *)dictionary;
-(IADevice *)ownDevice;
-(IALocator *)locator;

@end

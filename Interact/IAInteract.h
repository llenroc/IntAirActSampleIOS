#import <Foundation/Foundation.h>

@class RKObjectManager;
@class RKObjectMappingProvider;
@class RKObjectMappingResult;
@class RKObjectRouter;
@class RKObjectSerializer;
@class RoutingHTTPServer;

@class IADevice;

@interface IAInteract : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, strong) RoutingHTTPServer * httpServer;
@property (nonatomic, strong) RKObjectMappingProvider * objectMappingProvider;
@property (nonatomic, strong) IADevice * ownDevice;
@property (nonatomic, strong) RKObjectRouter * router;

-(BOOL)start:(NSError **)errPtr;
-(void)stop;
-(RKObjectManager *)objectManagerForDevice:(IADevice *)device;
-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager;
-(RKObjectSerializer *)serializerForObject:(id)object;
-(NSArray *)getDevices;
-(RKObjectMappingResult *)deserializeObject:(NSData *)data;
-(RKObjectMappingResult *)deserializeDictionary:(NSDictionary *)dictionary;

@end

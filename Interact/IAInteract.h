//
//  IAInteract.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-28.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RKObjectSerializer;
@class RKObjectManager;
@class RKObjectMappingProvider;
@class RKObjectRouter;
@class RKObjectMappingResult;
@class RoutingHTTPServer;

@class IADevice;

@interface IAInteract : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (strong, nonatomic) RKObjectMappingProvider * objectMappingProvider;
@property (strong, nonatomic) RKObjectRouter * router;
@property (strong, nonatomic) RoutingHTTPServer * httpServer;
@property (strong, nonatomic) IADevice * ownDevice;

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device;
-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager;
-(RKObjectSerializer *)serializerForObject:(id)object;
-(NSArray *)getDevices;
-(BOOL)start:(NSError **)errPtr;
-(void)stop;
-(RKObjectMappingResult*)deserializeObject:(NSData*)data;

@end

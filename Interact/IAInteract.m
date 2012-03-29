//
//  IAInteract.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-28.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAInteract.h"
#import "IAImages.h"
#import "IAIMage.h"
#import "IADevice.h"
#import "IAImageServerMapper.h"

@interface IAInteract ()

@property (strong, nonatomic) RKObjectMappingProvider * objectMappingProvider;
@property (strong, nonatomic) IAImageServerMapper * imageServerMapper;
@property (strong, nonatomic) RKObjectRouter * router;
@property (strong, nonatomic) NSMutableDictionary * objectManagers;

@end

@implementation IAInteract

@synthesize objectMappingProvider = _objectMappingProvider;
@synthesize imageServerMapper = _imageServerMapper;
@synthesize router = _router;
@synthesize objectManagers = _objectManagers;

- (id)init
{
    self = [super init];
    if (self) {
        self.objectMappingProvider = [[RKObjectMappingProvider alloc] init];
        
        RKObjectMapping* imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
        imageMapping.rootKeyPath = @"images";
        
        [imageMapping mapKeyPath:@"id" toAttribute:@"identifier"];
        [imageMapping mapKeyPath:@"name" toAttribute:@"name"];
        [imageMapping mapKeyPath:@"src" toAttribute:@"location"];
        
        RKObjectMapping* imageSerialization = [imageMapping inverseMapping];
        imageSerialization.rootKeyPath = @"images";
        
        [self.objectMappingProvider setMapping:imageMapping forKeyPath:@"images"];
        [self.objectMappingProvider setSerializationMapping:imageSerialization forClass:[IAImage class]];
        
        RKObjectMapping* imagesMapping = [RKObjectMapping mappingForClass:[IAImages class]];
        [imagesMapping hasMany:@"images" withMapping:imageMapping];
        RKObjectMapping* imagesSerialization = [imagesMapping inverseMapping];
        [self.objectMappingProvider setSerializationMapping:imagesSerialization forClass:[IAImages class]];
        
        // Create a router that maps resource paths to request methods
        self.router = [RKObjectRouter new];
        [self.router routeClass:[IAImage class] toResourcePath:@"/images" forMethod:RKRequestMethodPOST];
        [self.router routeClass:[IAImage class] toResourcePath:@"/images/(identifier)"];
        
        self.imageServerMapper = [[IAImageServerMapper alloc] initWithObjectMappingProvider:self.objectMappingProvider];
        self.imageServerMapper.imageServer = [[IAImageServer alloc] init];
        [self.imageServerMapper startServer];
        
        self.objectManagers = [[NSMutableDictionary alloc] init];

    }
    return self;
}

- (RKObjectManager *)objectManagerForDevice:(IADevice *)device {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    RKObjectManager * manager = [self.objectManagers objectForKey:device.hostAndPort];
    
    if(!manager) {
        manager = [[RKObjectManager alloc] initWithBaseURL:device.hostAndPort];
        
        // Ask for & generate JSON
        manager.acceptMIMEType = RKMIMETypeJSON;
        manager.serializationMIMEType = RKMIMETypeJSON;
        
        manager.mappingProvider = self.objectMappingProvider;
        
        // Register the router
        manager.router = self.router;
        
        [self.objectManagers setObject:manager forKey:device.hostAndPort];
        
        return manager;
    }
    
    return manager;
}

- (NSString*)resourcePathFor:(NSObject*)resource withAction:(NSString*)action forObjectManager:(RKObjectManager *)manager{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSString* path = [manager.router resourcePathForObject:resource method:RKRequestMethodPUT];
    path = [path stringByAppendingString:@"/"];
    path = [path stringByAppendingString:action];
    return path;
}

@end

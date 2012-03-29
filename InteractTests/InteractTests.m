//
//  InteractTests.m
//  InteractTests
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface InteractTests : SenTestCase

@end

#import <RestKit/RestKit.h>
#import <RestKit+Blocks/RestKit+Blocks.h>
#import "IAImage.h"
#import "IAImages.h"

@implementation InteractTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testBasicRestKit
{
    RKObjectManager * manager = [[RKObjectManager alloc] initWithBaseURL:@"http://localhost:4567"];
    STAssertNotNil(manager, @"The manager should not be NIL");
    
    __block int done=0;
    [manager loadObjectsAtResourcePath:@"images" handler:^(RKObjectLoader *loader, NSError *error) {
        STAssertNotNil(manager, @"The manager should not be NIL");
        done=1;
    }];
    
    // http://stackoverflow.com/questions/3615939/wait-for-code-to-finish-execution
    while (!done) {
        // This executes another run loop.
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        // Sleep 1/100th sec
        usleep(10000);
    }
}

- (void)testObjectMapping
{
    RKObjectMapping* imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
    imageMapping.rootKeyPath = @"images";
    
    [imageMapping mapKeyPath:@"id" toAttribute:@"identifier"];
    [imageMapping mapKeyPath:@"name" toAttribute:@"name"];
    [imageMapping mapKeyPath:@"src" toAttribute:@"location"];
    
    RKObjectMapping* imageSerialization = [imageMapping inverseMapping];
    imageSerialization.rootKeyPath = @"images";
    
    
    
    RKObjectMappingProvider * objectMappingProvider = [[RKObjectMappingProvider alloc] init];    
    [objectMappingProvider setMapping:imageMapping forKeyPath:@"images"];
    [objectMappingProvider setSerializationMapping:imageSerialization forClass:[IAImage class]];
    
    RKObjectMapping* imagesMapping = [RKObjectMapping mappingForClass:[IAImages class]];
    [imagesMapping hasMany:@"images" withMapping:imageMapping];
    RKObjectMapping* imagesSerialization = [imagesMapping inverseMapping];
    [objectMappingProvider setSerializationMapping:imagesSerialization forClass:[IAImages class]];
    
    IAImage* image = [IAImage new];
    image.identifier = [NSNumber numberWithInt:1];
    image.name = @"image";
    image.location = @"https://encrypted.google.com/images/srpr/logo3w.png";
    
    IAImage* image2 = [IAImage new];
    image2.identifier = [NSNumber numberWithInt:1];
    image2.name = @"image";
    image2.location = @"https://encrypted.google.com/images/srpr/logo3w.png";
    
    NSMutableArray* imageArray = [[NSMutableArray alloc] init];
    [imageArray addObject:image];
    [imageArray addObject:image2];
    
    IAImages * images = [[IAImages alloc] init];
    images.images = imageArray;
    
    id serialize = images;
    RKObjectMapping * mapping = [objectMappingProvider serializationMappingForClass:[serialize class]];
    RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:serialize mapping:mapping];
    
    NSError* error = nil;
    
    NSDictionary * dict = [serializer serializedObject:&error];
    NSLog(@"%@", dict);
    
    id obj = [dict objectForKey:@"images"];
    NSLog(@"%@", [obj class]);
    
    NSString* JSON = [serializer serializedObjectForMIMEType:RKMIMETypeJSON error:&error];
    NSLog(@"%@", JSON);

}

@end

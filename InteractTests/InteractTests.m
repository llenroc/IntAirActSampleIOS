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
    RKObjectManager * manager = [[RKObjectManager alloc] initWithBaseURL:[RKURL URLWithString:@"http://localhost:4567"]];
    STAssertNotNil(manager, @"The manager should not be NIL");
    
    __block int done=0;
    [manager loadObjectsAtResourcePath:@"/images" handler:^(RKObjectLoader *loader, NSError *error) {
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
    RKObjectMappingProvider * objectMappingProvider = [RKObjectMappingProvider new];
    
    RKObjectMapping* imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
    imageMapping.rootKeyPath = @"images";
    [imageMapping mapKeyPath:@"id" toAttribute:@"identifier"];
    [imageMapping mapKeyPath:@"name" toAttribute:@"name"];
    [imageMapping mapKeyPath:@"src" toAttribute:@"location"];
    [objectMappingProvider setMapping:imageMapping forKeyPath:@"images"];
    
    RKObjectMapping* imageSerialization = [imageMapping inverseMapping];
    imageSerialization.rootKeyPath = @"images";
    [objectMappingProvider setSerializationMapping:imageSerialization forClass:[IAImage class]];
    
    RKObjectMapping* imagesMapping = [RKObjectMapping mappingForClass:[IAImages class]];
    [imagesMapping hasMany:@"images" withMapping:imageMapping];
    RKObjectMapping* imagesSerialization = [imagesMapping inverseMapping];
    [objectMappingProvider setSerializationMapping:imagesSerialization forClass:[IAImages class]];
    
    IAImage* image = [IAImage new];
    image.identifier = [NSNumber numberWithInt:1];
    
    IAImage* image2 = [IAImage new];
    image2.identifier = [NSNumber numberWithInt:2];
    
    NSMutableArray* imageArray = [NSMutableArray new];
    [imageArray addObject:image];
    [imageArray addObject:image2];
    
    IAImages * images = [IAImages new];
    images.images = imageArray;
    
    id serialize = images;
    RKObjectMapping * mapping = [objectMappingProvider serializationMappingForClass:[serialize class]];
    STAssertNotNil(mapping, @"Mapping should not be NIL");
    RKObjectSerializer * serializer = [RKObjectSerializer serializerWithObject:serialize mapping:mapping];
    STAssertNotNil(serializer.mapping, @"Mapping should not be NIL");
    
    NSError * error = nil;

    //- (id)serializedObject:(NSError**)error {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    //RKObjectMappingOperation* operation = [RKObjectMappingOperation mappingOperationFromObject:serialize toObject:dictionary withMapping:mapping];
    
    RKManagedObjectMappingOperation * t4 = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:serialize destinationObject:dictionary mapping:mapping];
    RKObjectMappingOperation * t3 = [[RKObjectMappingOperation alloc] initWithSourceObject:serialize destinationObject:dictionary mapping:mapping];
    
    Class targetClass = [NSClassFromString(@"RKManagedObjectMappingOperation") class];
    Class targetClass2 = [RKManagedObjectMappingOperation class];
    if (targetClass == nil) {
        targetClass = [RKObjectMappingOperation class];
    }
    DDLogInfo(@"%@", targetClass);
    id alloc1 = [targetClass alloc];
    id alloc2 = [targetClass2 alloc];
    RKManagedObjectMappingOperation * t1 = [alloc1 initWithSourceObject:serialize destinationObject:dictionary mapping:mapping];
    
    NSDictionary * dict = [serializer serializedObject:&error];
    NSLog(@"%@", dict);

    id obj = [dict objectForKey:@"images"];
    NSLog(@"%@", [obj class]);

    NSString* JSON = [serializer serializedObjectForMIMEType:RKMIMETypeJSON error:&error];
    NSLog(@"%@", JSON);
}



@end

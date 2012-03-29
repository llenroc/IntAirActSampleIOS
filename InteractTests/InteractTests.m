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

- (void)testExample
{
    RKObjectManager * manager = [[RKObjectManager alloc] initWithBaseURL:@"http://localhost"];
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

@end

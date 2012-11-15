#import "IAPhotoBrowser.h"

#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>
#import <RestKit/RestKit.h>

#import "IAImage.h"
#import "IASwipeGestureRecognizer.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IAPhotoBrowser

- (id)init
{
    self = [super init];
    if (self) {
        self.delegate = self;
        self.displayActionButton = YES;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    DDLogVerbose(@"%@: %@, animated: %i", THIS_FILE, THIS_METHOD, animated);
    [super viewWillAppear:animated];
    
    int numberOfTouches = 1;
    
    IASwipeGestureRecognizer * swipeUp = [[IASwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.numberOfTouchesRequired = numberOfTouches;
    
    IASwipeGestureRecognizer * swipeDown = [[IASwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.numberOfTouchesRequired = numberOfTouches;
    
    [self.view addGestureRecognizer:swipeUp];
    [self.view addGestureRecognizer:swipeDown];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.imageURLs.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.imageURLs.count) {
        return [MWPhoto photoWithURL:self.imageURLs[index]];
    }
    return nil;
}

-(IBAction)handleSwipe:(IASwipeGestureRecognizer *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if(self.imageURLs.count == 0 || self.index > self.imageURLs.count) {
        return;
    }
    
    NSString * url = [self.imageURLs objectAtIndex:self.index];

    IARequest * request = [IARequest requestWithRoute:[IARoute routeWithAction:@"PUT" resource:@"/views/image"] metadata:nil parameters:nil origin:self.intAirAct.ownDevice body:[url dataUsingEncoding:NSUTF8StringEncoding]];

    NSArray * devices = [self.intAirAct devicesSupportingRoute:[IARoute routeWithAction:@"PUT" resource:@"/action/displayImage"]];
    if([devices count] == 0) {
        [self.intAirAct sendRequest:request toDevice:self.intAirAct.ownDevice];
    } else {
        for(IADevice * dev in self.intAirAct.devices) {
            [self.intAirAct sendRequest:request toDevice:dev];
        }
    }

}

@end

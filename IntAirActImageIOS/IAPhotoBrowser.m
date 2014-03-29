#import "IAPhotoBrowser.h"

#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>

#import "IAImage.h"
#import "IASwipeGestureRecognizer.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

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
    
    if(self.imageURLs.count == 0 || self.currentIndex > self.imageURLs.count) {
        return;
    }
    
    NSURL * url = [self.imageURLs objectAtIndex:self.currentIndex];

    IARoute * route = [IARoute put:@"/image"];
    IARequest * request = [IARequest requestWithRoute:route metadata:nil parameters:nil origin:self.intAirAct.ownDevice body:nil];
    [request setBodyWithString:[url absoluteString]];

    NSArray * devices = [self.intAirAct devicesSupportingRoute:route];
    if([devices count] == 0) {
        [self.intAirAct sendRequest:request toDevice:self.intAirAct.ownDevice];
    } else {
        for(IADevice * dev in self.intAirAct.devices) {
            [self.intAirAct sendRequest:request toDevice:dev];
        }
    }

}

@end

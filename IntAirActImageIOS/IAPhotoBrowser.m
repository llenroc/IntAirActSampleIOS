#import "IAPhotoBrowser.h"

#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>
#import <RestKit/RestKit.h>

#import "IAImageClient.h"
#import "IASwipeGestureRecognizer.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface IAPhotoBrowser ()

@property (nonatomic, strong) IAImageClient * imageClient;
@property (nonatomic, strong) NSArray * images;

@end

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
    
    [self loadImages];
}

-(void)loadImages
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if(self.intAirAct && self.device) {
        [self.imageClient getImages:^(NSArray * imgs) {
            DDLogVerbose(@"Loaded images: %@ from device: %@", imgs, self.device);
            self.images = imgs;
            [self reloadData];
            if(self.image) {
                NSUInteger index = [imgs indexOfObject:self.image];
                if(index != NSNotFound) {
                    [self setInitialPageIndex:index];
                }
            }
        } fromDevice:self.device];
    }
}

-(IAImageClient *)imageClient
{
    if (!_imageClient) {
        _imageClient = [[IAImageClient alloc] initWithIntAirAct:self.intAirAct];
    }
    return _imageClient;
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.images.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.images.count) {
        RKObjectManager * om = [self.intAirAct objectManagerForDevice:self.device];
        NSString * loc = [self.intAirAct resourcePathFor:[self.images objectAtIndex:index] forObjectManager:om];
        loc = [loc stringByAppendingString:@".jpg"];
        RKURL * url = [om.baseURL URLByAppendingResourcePath:loc];
        return [MWPhoto photoWithURL:url];
    }
    return nil;
}

-(IBAction)handleSwipe:(IASwipeGestureRecognizer *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if(self.images.count == 0 || self.index > self.images.count) {
        return;
    }
    
    IAImage * img = [self.images objectAtIndex:self.index];
    
    NSArray * devices = [self.intAirAct devicesSupportingRoute:[IARoute routeWithAction:@"PUT" resource:@"/action/displayImage"]];
    
    if([devices count] == 0) {
        [self.imageClient displayImage:img ofDevice:self.device onDevice:self.device];
    } else {
        NSMutableArray * devs = [devices mutableCopy];
        [devs removeObject:self.intAirAct.ownDevice];
        
        for(IADevice * dev in devs) {
            [self.imageClient displayImage:img ofDevice:self.device onDevice:dev];
        }
    }
}

@end

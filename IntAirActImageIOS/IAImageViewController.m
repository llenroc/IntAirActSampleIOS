#import "IAImageViewController.h"

#import <CocoaLumberjack/DDLog.h>
#import <RestKit/RestKit.h>
#import <IntAirAct/IADevice.h>
#import <IntAirAct/IAIntAirAct.h>

#import "IAImage.h"
#import "IAImageClient.h"
#import "IASwipeGestureRecognizer.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAImageViewController ()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView * activity;
@property (nonatomic, weak) IBOutlet UIImageView * imageView;


@end

@implementation IAImageViewController

-(void)loadImage
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if (self.imageView) {
        if (self.image && self.device) {
            [self.activity startAnimating];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                RKObjectManager * om = [self.intAirAct objectManagerForDevice:self.device];
                NSString * loc = [self.intAirAct resourcePathFor:self.image forObjectManager:om];
                loc = [loc stringByAppendingString:@".jpg"];
                RKURL * url = [om.baseURL URLByAppendingResourcePath:loc];
                UIImage * image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = image;
                    [self.activity stopAnimating];
                });
            });
        } else {
            self.imageView.image = nil;
        }
    }
}

-(void)setImage:(IAImage *)image
{
    if (![_image isEqual:image]) {
        _image = image;
        self.title = [NSString stringWithFormat:@"Image %i", [image.identifier intValue]];
        if (self.imageView.window) {    // we're on screen, so update the image
            [self loadImage];           
        } else {                        // we're not on screen, so no need to loadImage (it will happen next viewWillAppear:)
            self.imageView.image = nil; // but image has changed (so we can't leave imageView.image the same, so set to nil)
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [super viewWillAppear:animated];
    
    int numberOfTouches = 1;
    
    IASwipeGestureRecognizer * swipeUp = [[IASwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.numberOfTouchesRequired = numberOfTouches;
    
    IASwipeGestureRecognizer * swipeDown = [[IASwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.numberOfTouchesRequired = numberOfTouches;
    
    IASwipeGestureRecognizer * swipeRight = [[IASwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.numberOfTouchesRequired = numberOfTouches;
    
    IASwipeGestureRecognizer * swipeLeft = [[IASwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.numberOfTouchesRequired = numberOfTouches;
    
    [self.view addGestureRecognizer:swipeUp];
    [self.view addGestureRecognizer:swipeDown];
    [self.view addGestureRecognizer:swipeRight];
    [self.view addGestureRecognizer:swipeLeft];

    if (!self.imageView.image && self.image) {
        [self loadImage];
    }
}

-(IBAction)handleSwipe:(IASwipeGestureRecognizer *)sender
{
    if([self.intAirAct.devices count] == 1) {
        [self.imageClient displayImage:self.image ofDevice:self.device onDevice:[self.intAirAct.devices anyObject]];
    } else {
        NSMutableArray * devices = [self.intAirAct.devices mutableCopy];
        [devices removeObject:self.intAirAct.ownDevice];
        
        for(IADevice * dev in devices) {
            [self.imageClient displayImage:self.image ofDevice:self.device onDevice:dev];
        }
    }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)viewDidUnload
{
    self.activity = nil;
    self.imageView = nil;
    [super viewDidUnload];
}

-(IAImageClient *)imageClient
{
    if (!_imageClient) {
        _imageClient = [[IAImageClient alloc] initWithIntAirAct:self.intAirAct];
    }
    return _imageClient;
}

@end

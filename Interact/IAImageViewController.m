#import "IAImageViewController.h"

#import <CocoaLumberjack/DDLog.h>
#import <RestKit/RestKit.h>

#import "IADevice.h"
#import "IALocator.h"
#import "IAInteract.h"
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

@synthesize device = _device;
@synthesize image = _image;
@synthesize imageClient = _imageClient;
@synthesize interact = _interact;

@synthesize activity = _activity;
@synthesize imageView = _imageView;

-(void)loadImage
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if (self.imageView) {
        if (self.image && self.device) {
            [self.activity startAnimating];
            dispatch_queue_t imageDownloadQ = dispatch_queue_create("Interact Image Downloader", NULL);
            dispatch_async(imageDownloadQ, ^{
                RKObjectManager * om = [self.interact objectManagerForDevice:self.device];
                NSString * loc = [self.interact resourcePathFor:self.image forObjectManager:om];
                loc = [loc stringByAppendingString:@".jpg"];
                RKURL * url = [om.baseURL URLByAppendingResourcePath:loc];
                UIImage * image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = image;
                    [self.activity stopAnimating];
                });
            });
            dispatch_release(imageDownloadQ);
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
    float angle = [self.interact.locator realAngle:[sender touchAngle]];
    //DDLogVerbose(@"Angle: %f", angle);
    
    if([self.interact.devices count] == 1) {
        [self.imageClient displayImage:self.image ofDevice:self.device onDevice:[self.interact.devices lastObject]];
    } else {
        NSMutableArray * devices = [self.interact.devices mutableCopy];
        [devices removeObject:self.interact.ownDevice];

        IADevice * dev;
        if (angle < M_PI_2) {
            dev = [devices objectAtIndex:0];
        } else if (angle < M_PI && [devices count] > 0) {
            dev = [devices objectAtIndex:1];
        } else if (angle < M_PI_2 * 3 && [devices count] > 1) {
            dev = [devices objectAtIndex:2];
        } else if (angle < M_PI * 2 && [devices count] > 2) {
            dev = [devices objectAtIndex:3];
        }
        if (dev) {
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
        _imageClient = [[IAImageClient alloc] initWithInteract:self.interact];
    }
    return _imageClient;
}

@end

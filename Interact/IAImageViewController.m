#import "IAImageViewController.h"

#import <RestKit/RestKit.h>

#import "IADevice.h"
#import "IAInteract.h"
#import "IAImage.h"
#import "IAImageClient.h"

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
        if (self.image) {
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
    
    UISwipeGestureRecognizer * swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.numberOfTouchesRequired = numberOfTouches;
    
    UISwipeGestureRecognizer * swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.numberOfTouchesRequired = numberOfTouches;
    
    UISwipeGestureRecognizer * swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.numberOfTouchesRequired = numberOfTouches;
    
    UISwipeGestureRecognizer * swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
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

-(IBAction)handleSwipe:(UISwipeGestureRecognizer *)sender
{
    DDLogVerbose(@"Recognized swipe %i", [sender direction]);
    if([self.interact.devices count] == 1) {
        [self.imageClient displayImage:self.image ofDevice:self.device onDevice:[self.interact.devices lastObject]];
    } else {
        for(IADevice * dev in self.interact.devices) {
            if(![dev isEqual:self.interact.ownDevice]) {
                [self.imageClient displayImage:self.image ofDevice:self.device onDevice:dev];
            }
        }
    }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)viewDidUnload
{
    self.imageView = nil;
    self.activity = nil;
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

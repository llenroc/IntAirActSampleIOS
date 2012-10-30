#import "IASwipeGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>
#import <CocoaLumberjack/DDLog.h>

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IASwipeGestureRecognizer ()

@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGPoint endPoint;

@end

@implementation IASwipeGestureRecognizer

- (void)reset
{
    [super reset];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    self.startPoint = [touch locationInView:touch.view];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (self.state ==  UIGestureRecognizerStateRecognized) {
        UITouch * touch = [touches anyObject];
        self.endPoint = [touch locationInView:touch.view];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
}

-(float)swipeAngle
{
    // this is the swipe direction, the result is between [-pi,pi]
    float angle = atan2(-(self.endPoint.y - self.startPoint.y), self.endPoint.x - self.startPoint.x);

    // rotate it by 90 to the left so that a swipe up is 0
    angle -= M_PI_2;

    // account for device orientation
    switch([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            break;
        case UIInterfaceOrientationLandscapeLeft:
            // the device has been rotated to the right, thus the interface has been rotated to the left
            angle -= M_PI_2 * 3;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angle -= M_PI;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle -= M_PI_2;
            // the device has been rotated to the left, thus the interface has been rotated to the right
            break;
    }

    while (angle < 0) {
        angle += M_PI * 2;
    }

    DDLogVerbose(@"%@: You swiped at %f", THIS_FILE, angle * 180 / M_PI);

    return angle;
}

@end

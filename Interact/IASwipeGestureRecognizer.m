#import "IASwipeGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

@interface IASwipeGestureRecognizer () {
    CGPoint startPoint;
    CGPoint endPoint;
}

@end

@implementation IASwipeGestureRecognizer

- (void)reset
{
    [super reset];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    startPoint = [touch locationInView:touch.view];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (self.state ==  UIGestureRecognizerStateRecognized) {
        UITouch * touch = [touches anyObject];
        endPoint = [touch locationInView:touch.view];
        [self touchAngle];
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

-(float)touchAngle
{
    // this is the swipe direction, it is in [-pi,pi]
    float angle = atan2(-(endPoint.y - startPoint.y), endPoint.x - startPoint.x);
    
    // change the angle to be from [0,2*pi]
    if (angle < 0) {
        angle += M_PI * 2;
    }
    //DDLogVerbose(@"Angle: %f", angle);

    return angle;
}

@end

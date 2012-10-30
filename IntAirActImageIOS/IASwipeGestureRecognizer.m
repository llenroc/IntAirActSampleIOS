#import "IASwipeGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

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
    // this is the swipe direction, the result is between [-pi,pi]
    float angle = atan2(-(self.endPoint.y - self.startPoint.y), self.endPoint.x - self.startPoint.x);
    
    // change the angle to be between [0,2*pi]
    if (angle < 0) {
        angle += M_PI * 2;
    }

    return angle;
}

@end

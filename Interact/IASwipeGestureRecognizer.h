#import <UIKit/UIKit.h>

#import <UIKit/UIGestureRecognizerSubclass.h>

@interface IASwipeGestureRecognizer : UISwipeGestureRecognizer

- (void)reset;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(float)touchAngle;

@end

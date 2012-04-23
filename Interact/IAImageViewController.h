#import <UIKit/UIKit.h>

@class IAInteract;
@class IAImage;
@class IAImageClient;

@interface IAImageViewController : UIViewController

@property (nonatomic, strong) IAImage * image;
@property (nonatomic, strong) IAImageClient * imageClient;
@property (nonatomic, strong) IAInteract * interact;

@end

#import <UIKit/UIKit.h>

@class IADevice;
@class IAIntAirAct;
@class IAImage;
@class IAImageClient;

@interface IAImageViewController : UIViewController

@property (nonatomic, strong) IADevice * device;
@property (nonatomic, strong) IAImage * image;
@property (nonatomic, strong) IAImageClient * imageClient;
@property (nonatomic, strong) IAIntAirAct * intAirAct;

@end

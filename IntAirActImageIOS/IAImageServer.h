#import <Foundation/Foundation.h>

@class IAAction;
@class IADevice;
@class IAImage;
@class IAIntAirAct;

@interface IAImageServer : NSObject

+(IAImageServer*)serverWithIntAirAct:(IAIntAirAct *)value navigationController:(UINavigationController *)navigationController;

@end

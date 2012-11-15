#import <Foundation/Foundation.h>

@class IAAction;
@class IADevice;
@class IAImage;
@class IAIntAirAct;

@interface IAServer : NSObject

+(IAServer*)serverWithIntAirAct:(IAIntAirAct *)value navigationController:(UINavigationController *)navigationController;

@end

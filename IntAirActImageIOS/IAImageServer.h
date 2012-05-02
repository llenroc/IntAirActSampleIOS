#import <Foundation/Foundation.h>

@class IAIntAirAct;

@interface IAImageServer : NSObject

@property (nonatomic, weak) UINavigationController * navigationController;

-(id)initWithIntAirAct:(IAIntAirAct*)intAirAct;

@end

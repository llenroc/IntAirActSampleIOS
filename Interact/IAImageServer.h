#import <Foundation/Foundation.h>

@class IAInteract;

@interface IAImageServer : NSObject

@property (nonatomic, weak) UINavigationController * navigationController;

-(id)initWithInteract:(IAInteract*)interact;

@end

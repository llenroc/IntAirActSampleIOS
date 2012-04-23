#import <Foundation/Foundation.h>

@class IADevice;

@interface IAImage : NSObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) IADevice * device;

@end

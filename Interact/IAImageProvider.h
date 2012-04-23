#import <Foundation/Foundation.h>

@interface IAImageProvider : NSObject

@property (nonatomic, strong) NSArray * images;

-(NSData*)imageAsData:(NSNumber*)identifier;

@end

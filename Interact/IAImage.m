#import "IAImage.h"

@implementation IAImage

@synthesize identifier = _identifier;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAImage[identifier: %@]", self.identifier];
}

@end

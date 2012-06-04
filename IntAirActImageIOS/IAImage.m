#import "IAImage.h"

@implementation IAImage

@synthesize identifier = _identifier;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAImage[identifier: %@]", self.identifier];
}

-(BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[self class]]) {
        IAImage * other = (IAImage *) object;
        return self.identifier == other.identifier;
    }
    return [super isEqual:object];
}

@end

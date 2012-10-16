#import "IAImage.h"

@implementation IAImage

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAImage[identifier: %@]", self.identifier];
}

-(BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[self class]]) {
        IAImage * other = (IAImage *) object;
        return [self.identifier isEqual:other.identifier];
    }
    return [super isEqual:object];
}

@end

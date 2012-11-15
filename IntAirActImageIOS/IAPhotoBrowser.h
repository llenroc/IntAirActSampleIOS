#import <MWPhotoBrowser/MWPhotoBrowser.h>

@class IADevice;
@class IAIntAirAct;
@class IAImage;

@interface IAPhotoBrowser : MWPhotoBrowser <MWPhotoBrowserDelegate>

@property (nonatomic, strong) IAIntAirAct * intAirAct;
@property (nonatomic, strong) NSArray * imageURLs;

@end

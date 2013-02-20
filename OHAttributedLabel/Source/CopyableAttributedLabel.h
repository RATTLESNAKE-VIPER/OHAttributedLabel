//
//  CopyableLabel.h
//
//  Created by Gautam Lodhiya on 19/02/13.
//

#import "OHAttributedLabel.h"

@protocol CopyableAttributedLabelDelegate <NSObject>

@optional
- (void)showUIMenuControllerAtLocation:(CGPoint)location;
- (void)hideUIMenuController;
- (NSString*)stringToCopyToClipboard;

@end

@interface CopyableAttributedLabel : OHAttributedLabel

@property (nonatomic, assign)id<CopyableAttributedLabelDelegate> copyableDelegate;

@end

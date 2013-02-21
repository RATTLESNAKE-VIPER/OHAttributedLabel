//
//  CopyableLabel.h
//
//  Created by Gautam Lodhiya on 19/02/13.
//

#import "OHAttributedLabel.h"

@protocol CopyableAttributedLabelDelegate <NSObject>

@optional
- (void)showViewAtLocation:(CGPoint)location;
- (void)hideView;
- (NSString*)stringToCopyToClipboard;

@end

@interface CopyableAttributedLabel : OHAttributedLabel

@property (nonatomic, assign)id<CopyableAttributedLabelDelegate> copyableDelegate;

@end

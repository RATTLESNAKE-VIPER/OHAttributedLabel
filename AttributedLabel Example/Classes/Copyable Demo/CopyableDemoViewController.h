//
//  CopyableDemoViewController.h
//  AttributedLabel Example
//
//  Created by Gautam Lodhiya on 19/02/13.
//
//

#import <UIKit/UIKit.h>
#import <OHAttributedLabel/CopyableAttributedLabel.h>

@interface CopyableDemoViewController : UIViewController<CopyableAttributedLabelDelegate>
@property (retain, nonatomic) IBOutlet CopyableAttributedLabel *copyableAttributedLabel;

@end

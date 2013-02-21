//
//  CopyableDemoViewController.m
//  AttributedLabel Example
//
//  Created by Gautam Lodhiya on 19/02/13.
//
//

#import "CopyableDemoViewController.h"
#import <OHAttributedLabel/NSAttributedString+Attributes.h>
#import <OHAttributedLabel/OHASBasicHTMLParser.h>


@interface CopyableDemoViewController ()

@end

@implementation CopyableDemoViewController
@synthesize copyableAttributedLabel = _copyableAttributedLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    // Note: Setting Delegate is optional
    self.copyableAttributedLabel.copyableDelegate = self; //optional properties
    self.copyableAttributedLabel.highlightedLinkColor = [UIColor colorWithRed:188.0f/255.0f green:210.0f/255.0f blue:229.0f/255.0f alpha:1]; //optional properties
    
    self.copyableAttributedLabel.attributedText = [OHASBasicHTMLParser attributedStringByProcessingMarkupInAttributedString:self.copyableAttributedLabel.attributedText];


    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#if ! __has_feature(objc_arc)
- (void)dealloc {
    [_copyableAttributedLabel release];
    [super dealloc];
}
#endif

- (void)viewDidUnload {
    [self setCopyableAttributedLabel:nil];
    [super viewDidUnload];
}





#pragma mark -
#pragma mark CopyableAttributedLabelDelegate Methods

- (void)showViewAtLocation:(CGPoint)location
{
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setTargetRect:CGRectMake(location.x, location.y, 0.0f, 0.0f) inView:self.copyableAttributedLabel];
    [menu setMenuVisible:YES animated:YES];
}

- (void)hideView
{
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuVisible:NO animated:YES];
    [menu update];
}

- (NSString *)stringToCopyToClipboard
{
    return self.copyableAttributedLabel.attributedText.string;
}


@end

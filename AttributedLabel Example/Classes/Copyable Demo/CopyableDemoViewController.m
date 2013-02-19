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
@end

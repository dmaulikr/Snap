
#import "MainViewController.h"

@interface MainViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *sImageView;
@property (nonatomic, weak) IBOutlet UIImageView *nImageView;
@property (nonatomic, weak) IBOutlet UIImageView *aImageView;
@property (nonatomic, weak) IBOutlet UIImageView *pImageView;
@property (nonatomic, weak) IBOutlet UIImageView *jokerImageView;

@property (nonatomic, weak) IBOutlet UIButton *hostGameButton;
@property (nonatomic, weak) IBOutlet UIButton *joinGameButton;
@property (nonatomic, weak) IBOutlet UIButton *singlePlayerGameButton;
@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.hostGameButton rw_applySnapStyle];
    [self.joinGameButton rw_applySnapStyle];
    [self.singlePlayerGameButton rw_applySnapStyle];
}

- (IBAction)hostGameAction:(id)sender
{
}

- (IBAction)joinGameAction:(id)sender
{
}

- (IBAction)singlePlayerGameAction:(id)sender
{
}

@end

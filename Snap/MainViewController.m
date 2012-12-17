
#import "MainViewController.h"

@interface MainViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *sImageView;
@property (nonatomic, weak) IBOutlet UIImageView *nImageView;
@property (nonatomic, weak) IBOutlet UIImageView *aImageView;
@property (nonatomic, weak) IBOutlet UIImageView *pImageView;
@property (nonatomic, weak) IBOutlet UIImageView *jokerImageView;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *cards;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;

@property (nonatomic, weak) IBOutlet UIButton *hostGameButton;
@property (nonatomic, weak) IBOutlet UIButton *joinGameButton;
@property (nonatomic, weak) IBOutlet UIButton *singlePlayerGameButton;
@end

@implementation MainViewController
{
    BOOL _buttonsEnabled;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.hostGameButton rw_applySnapStyle];
    [self.joinGameButton rw_applySnapStyle];
    [self.singlePlayerGameButton rw_applySnapStyle];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareForIntroAnimation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performIntroAnimation];
}

#pragma mark - Private methods

#pragma mark - Animating the intro

- (void)prepareForIntroAnimation
{
    [self.cards enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden:YES];
    }];
    
    [self.buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setAlpha:0.0f];
    }];
    
    _buttonsEnabled = NO;
}

- (void)performIntroAnimation
{
    // Animate up and fan out cards
    
    // Horizontally centered, vertically below the bottom of the screen
    CGPoint point = CGPointMake(self.view.bounds.size.width / 2.0f, self.view.bounds.size.height * 2.0f);
    
    [self.cards enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setCenter:point];
    }];
    
    [self.cards enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden:NO];
    }];
    
    [UIView animateWithDuration:0.65f animations:^{
        self.sImageView.center = CGPointMake(80.0f, 108.0f);
        self.sImageView.transform = CGAffineTransformMakeRotation(-0.22f);
        
        self.nImageView.center = CGPointMake(160.0f, 93.0f);
        self.nImageView.transform = CGAffineTransformMakeRotation(-0.1f);
        
        self.aImageView.center = CGPointMake(240.0f, 88.0f);
        
        self.pImageView.center = CGPointMake(320.0f, 93.0f);
        self.pImageView.transform = CGAffineTransformMakeRotation(0.1f);
        
        self.jokerImageView.center = CGPointMake(400.0f, 108.0f);
        self.jokerImageView.transform = CGAffineTransformMakeRotation(0.22f);
    }
                     completion:nil];
    
    // Fade in buttons
    [UIView animateWithDuration:0.5f delay:1.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setAlpha:1.0f];
        }];
    } completion:^(BOOL finished) {
        _buttonsEnabled = YES;
    }];
}

#pragma mark - IBActions

- (IBAction)hostGameAction:(id)sender
{
}

- (IBAction)joinGameAction:(id)sender
{
}

- (IBAction)singlePlayerGameAction:(id)sender
{
}

- (void)viewDidUnload {
    [self setButtons:nil];
    [super viewDidUnload];
}
@end

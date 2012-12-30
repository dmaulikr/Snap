
#import "MainViewController.h"
#import "HostViewController.h"
#import "JoinViewController.h"
#import "GameViewController.h"
#import "Game.h"

@interface MainViewController () <HostViewControllerDelegate, JoinViewControllerDelegate, GameViewControllerDelegate>
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

@property (nonatomic, assign) BOOL buttonsEnabled;
@property (nonatomic, assign) BOOL performAnimations;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _performAnimations = YES;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        [button rw_applySnapStyle];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.performAnimations) [self prepareForIntroAnimation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.performAnimations) [self performIntroAnimation];
}

- (void)dealloc
{
    DLog(@"dealloc %@", self);
}

#pragma mark - Private

- (void)showDisconnectedAlert
{
    [[[UIAlertView alloc] initWithTitle:@"Disconnected" message:@"You were disconnected from the game." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)showNoNetworkAlert
{
    [[[UIAlertView alloc] initWithTitle:@"No Network" message:@"To use multiplayer, please enable Bluetooth or Wi-Fi in your device's Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)startGameWithBlock:(void (^)(Game *))block
{
    GameViewController *controller = [[GameViewController alloc] initWithNibName:@"GameViewController" bundle:nil];
    controller.delegate = self;
    
    [self presentViewController:controller animated:NO completion:^{
        Game *game = [Game new];
        controller.game = game;
        game.delegate = controller;
        block(game);
    }];
}

#pragma mark - Animating the intro

- (void)prepareForIntroAnimation
{
    [self.cards enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden:YES];
    }];
    
    [self.buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setAlpha:0.0f];
    }];
    
    self.buttonsEnabled = NO;
}

- (void)performIntroAnimation
{
    // Horizontally centered, vertically below the bottom of the screen
    CGPoint point = CGPointMake(self.view.bounds.size.width / 2.0f, self.view.bounds.size.height * 2.0f);
    
    [self.cards enumerateObjectsUsingBlock:^(UIImageView *card, NSUInteger idx, BOOL *stop) {
        card.center = point;
    }];
    
    [self.cards enumerateObjectsUsingBlock:^(UIImageView *card, NSUInteger idx, BOOL *stop) {
        card.hidden = NO;
    }];
    
    // Animate cards onscreen
    [UIView animateWithDuration:0.65f delay:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
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
        [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
            button.alpha = 1.0f;
        }];
    } completion:^(BOOL finished) {
        self.buttonsEnabled = YES;
    }];
}

#pragma mark - Animate presenting HostViewController

- (void)performExitAnimationWithCompletionBlock:(void (^)(BOOL))block
{
    self.buttonsEnabled = NO;
    
    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.cards enumerateObjectsUsingBlock:^(UIImageView *cardView, NSUInteger idx, BOOL *stop) {
            if (![cardView isEqual:self.aImageView]) { // "A" card does not animate horizontally
                cardView.center = self.aImageView.center;
                cardView.transform = self.aImageView.transform;
            }
        }];
    } completion:^(BOOL finished) {
        // Horizontally centered, vertically above the top of the screen
        CGPoint point = CGPointMake(self.aImageView.center.x, self.view.bounds.size.height * -2.0f);
        
        // Animate cards offscreen
        [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.cards enumerateObjectsUsingBlock:^(UIImageView *cardView, NSUInteger idx, BOOL *stop) {
                cardView.center = point;
            }];
        } completion:block];
        
        // Fade out buttons
        [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
                button.alpha = 0.0f;
            }];
        } completion:nil];
    }];
}

#pragma mark - IBActions

- (IBAction)hostGameAction:(id)sender
{
    if (self.buttonsEnabled) {
        [self performExitAnimationWithCompletionBlock:^(BOOL finished) {
            HostViewController *controller = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil];
            controller.delegate = self;
            [self presentViewController:controller animated:NO completion:nil];
        }];
    }
}

- (IBAction)joinGameAction:(id)sender
{
    if (self.buttonsEnabled) {
        [self performExitAnimationWithCompletionBlock:^(BOOL finished) {
            JoinViewController *controller = [[JoinViewController alloc] initWithNibName:@"JoinViewController" bundle:nil];
            controller.delegate = self;
            [self presentViewController:controller animated:NO completion:nil];
        }];
    }
}

- (IBAction)singlePlayerGameAction:(id)sender
{
    if (self.buttonsEnabled) {
        [self performExitAnimationWithCompletionBlock:^(BOOL finished) {
            [self startGameWithBlock:^(Game *game) {
                [game startSinglePlayerGame];
            }];
        }];
    }
}

#pragma mark - HostViewControllerDelegate

- (void)hostViewControllerDidCancel:(HostViewController *)controller
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)hostViewController:(HostViewController *)controller startGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients
{
    self.performAnimations = NO;
    
    [self dismissViewControllerAnimated:NO completion:^{
        self.performAnimations = YES;
        
        [self startGameWithBlock:^(Game *game) {
// Step #1 Start game with server player
            [game startServerGameWithSession:session playerName:name clients:clients];
        }];
    }];
}

- (void)hostViewController:(HostViewController *)controller didEndSessionWithReason:(QuitReason)reason
{
    if (reason == QuitReasonNoNetwork) {
        [self showNoNetworkAlert];
    }
}

#pragma mark - JoinViewControllerDelegate

- (void)joinViewControllerDidCancel:(JoinViewController *)controller
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)joinViewController:(JoinViewController *)controller startGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID
{
    self.performAnimations = NO;
    
    [self dismissViewControllerAnimated:NO completion:^{
        self.performAnimations = YES;
        
        [self startGameWithBlock:^(Game *game) {
            [game startClientGameWithSession:session playerName:name server:peerID];
        }];
    }];
}

- (void)joinViewController:(JoinViewController *)controller didDisconnectWithReason:(QuitReason)reason
{
    if (reason == QuitReasonNoNetwork) {
        [self showNoNetworkAlert];
    } else if (reason == QuitReasonConnectionDropped) {
        [self dismissViewControllerAnimated:NO completion:^{
            [self showDisconnectedAlert];
        }];
    }
}

#pragma mark - GameViewControllerDelegate

- (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason
{
    [self dismissViewControllerAnimated:NO completion:^{
        if (reason == QuitReasonConnectionDropped) {
            [self showDisconnectedAlert];
        }
    }];
}

@end

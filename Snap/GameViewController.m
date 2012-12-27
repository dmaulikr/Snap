//
//  GameViewController.m
//  Snap
//
//  Created by Scott Gardner on 12/18/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "GameViewController.h"
#import "Game.h"
#import "Player.h"
#import "Card.h"
#import "CardView.h"
#import "Stack.h"

@interface GameViewController () <UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *centerLabel;

@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, weak) IBOutlet UIView *cardContainerView;
@property (nonatomic, weak) IBOutlet UIButton *turnOverButton;
@property (nonatomic, weak) IBOutlet UIButton *snapButton;
@property (nonatomic, weak) IBOutlet UIButton *nextRoundButton;
@property (nonatomic, weak) IBOutlet UIImageView *wrongSnapImageView;
@property (nonatomic, weak) IBOutlet UIImageView *correctSnapImageView;

@property (nonatomic, weak) IBOutlet UILabel *playerNameBottomLabel;
@property (nonatomic, weak) IBOutlet UILabel *playerNameLeftLabel;
@property (nonatomic, weak) IBOutlet UILabel *playerNameTopLabel;
@property (nonatomic, weak) IBOutlet UILabel *playerNameRightLabel;

@property (nonatomic, weak) IBOutlet UILabel *playerWinsBottomLabel;
@property (nonatomic, weak) IBOutlet UILabel *playerWinsLeftLabel;
@property (nonatomic, weak) IBOutlet UILabel *playerWinsTopLabel;
@property (nonatomic, weak) IBOutlet UILabel *playerWinsRightLabel;

@property (nonatomic, weak) IBOutlet UIImageView *playerActiveBottomImageView;
@property (nonatomic, weak) IBOutlet UIImageView *playerActiveLeftImageView;
@property (nonatomic, weak) IBOutlet UIImageView *playerActiveTopImageView;
@property (nonatomic, weak) IBOutlet UIImageView *playerActiveRightImageView;

@property (nonatomic, weak) IBOutlet UIImageView *snapIndicatorBottomImageView;
@property (nonatomic, weak) IBOutlet UIImageView *snapIndicatorLeftImageView;
@property (nonatomic, weak) IBOutlet UIImageView *snapIndicatorTopImageView;
@property (nonatomic, weak) IBOutlet UIImageView *snapIndicatorRightImageView;

@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, strong) AVAudioPlayer *dealingCardsSound;
@property (nonatomic, strong) AVAudioPlayer *turnCardSound;

@property (nonatomic, strong) UIImageView *tappedView;
@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.centerLabel.font = [UIFont rw_snapFontWithSize:18.0f];
    
    self.snapButton.hidden = YES;
	self.nextRoundButton.hidden = YES;
	self.wrongSnapImageView.hidden = YES;
	self.correctSnapImageView.hidden = YES;
    
	[self hidePlayerLabels];
	[self hideActivePlayerIndicator];
	[self hideSnapIndicators];
    [self loadSounds];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
}

- (void)dealloc
{
    #ifdef DEBUG
    NSLog(@"dealloc %@", self);
    #endif
    
    [self.dealingCardsSound stop];
    [[ AVAudioSession sharedInstance] setActive:NO error:nil];
}

#pragma mark - Private methods

- (void)showPlayerLabels
{
	Player *player = [self.game playerAtPosition:PlayerPositionBottom];
    
	if (player) {
		self.playerNameBottomLabel.hidden = NO;
		self.playerWinsBottomLabel.hidden = NO;
	}
    
	player = [self.game playerAtPosition:PlayerPositionLeft];
    
	if (player) {
		self.playerNameLeftLabel.hidden = NO;
		self.playerWinsLeftLabel.hidden = NO;
	}
    
	player = [self.game playerAtPosition:PlayerPositionTop];
    
	if (player) {
		self.playerNameTopLabel.hidden = NO;
		self.playerWinsTopLabel.hidden = NO;
	}
    
	player = [self.game playerAtPosition:PlayerPositionRight];
    
	if (player) {
		self.playerNameRightLabel.hidden = NO;
		self.playerWinsRightLabel.hidden = NO;
	}
}

- (void)hidePlayerLabels
{
	self.playerNameBottomLabel.hidden = YES;
	self.playerWinsBottomLabel.hidden = YES;
    
	self.playerNameLeftLabel.hidden = YES;
	self.playerWinsLeftLabel.hidden = YES;
    
	self.playerNameTopLabel.hidden = YES;
	self.playerWinsTopLabel.hidden = YES;
    
	self.playerNameRightLabel.hidden = YES;
	self.playerWinsRightLabel.hidden = YES;
}

- (void)hideActivePlayerIndicator
{
	self.playerActiveBottomImageView.hidden = YES;
	self.playerActiveLeftImageView.hidden = YES;
	self.playerActiveTopImageView.hidden = YES;
	self.playerActiveRightImageView.hidden = YES;
}

- (void)hideSnapIndicators
{
	self.snapIndicatorBottomImageView.hidden = YES;
	self.snapIndicatorLeftImageView.hidden = YES;
	self.snapIndicatorTopImageView.hidden = YES;
	self.snapIndicatorRightImageView.hidden = YES;
}

- (void)hidePlayerLabelsForPlayer:(Player *)player
{
	switch (player.position) {
		case PlayerPositionBottom:
			self.playerNameBottomLabel.hidden = YES;
			self.playerWinsBottomLabel.hidden = YES;
			break;
            
		case PlayerPositionLeft:
			self.playerNameLeftLabel.hidden = YES;
			self.playerWinsLeftLabel.hidden = YES;
			break;
            
		case PlayerPositionTop:
			self.playerNameTopLabel.hidden = YES;
			self.playerWinsTopLabel.hidden = YES;
			break;
            
		case PlayerPositionRight:
			self.playerNameRightLabel.hidden = YES;
			self.playerWinsRightLabel.hidden = YES;
			break;
            
        default:
            break;
	}
}

- (void)hideActiveIndicatorForPlayer:(Player *)player
{
	switch (player.position)
	{
		case PlayerPositionBottom:
            self.playerActiveBottomImageView.hidden = YES;
            break;
            
		case PlayerPositionLeft:
            self.playerActiveLeftImageView.hidden = YES;
            break;
            
		case PlayerPositionTop:
            self.playerActiveTopImageView.hidden = YES;
            break;
            
		case PlayerPositionRight:
            self.playerActiveRightImageView.hidden = YES;
            break;
            
        default:
            break;
	}
}

- (void)hideSnapIndicatorForPlayer:(Player *)player
{
	switch (player.position)
	{
		case PlayerPositionBottom:
            self.snapIndicatorBottomImageView.hidden = YES;
            break;
            
		case PlayerPositionLeft:
            self.snapIndicatorLeftImageView.hidden = YES;
            break;
            
		case PlayerPositionTop:
            self.snapIndicatorTopImageView.hidden = YES;
            break;
            
		case PlayerPositionRight:
            self.snapIndicatorRightImageView.hidden = YES;
            break;
            
        default:
            break;
	}
}

- (void)loadSounds
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    [audioSession setActive:YES error:nil];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Dealing" withExtension:@"caf"];
    self.dealingCardsSound = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    
    // Setting a negative number cause loop to repeat indefinitely until stop is called
    self.dealingCardsSound.numberOfLoops = -1;
    
    [self.dealingCardsSound prepareToPlay];
    
    url = [[NSBundle mainBundle] URLForResource:@"TurnCard" withExtension:@"caf"];
    self.turnCardSound = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.turnCardSound prepareToPlay];
}

- (void)showTappedView
{
    Player *player = [self.game playerAtPosition:PlayerPositionBottom];
    Card *card = [player.closedCards topmostCard];
    
    if (card) {
        CardView *cardView = [self cardViewForCard:card];
        
        // Darken the card view of the topmost card
        if (!self.tappedView) {
            self.tappedView = [[UIImageView alloc] initWithFrame:cardView.bounds];
            self.tappedView.backgroundColor = [UIColor clearColor];
            self.tappedView.image = [UIImage imageNamed:@"Darken"];
            self.tappedView.alpha = 0.6f;
            [self.view addSubview:self.tappedView];
        } else {
            self.tappedView.hidden = NO;
        }
        
        self.tappedView.center = cardView.center;
        self.tappedView.transform = cardView.transform;
    }
}

- (void)hideTappedView
{
    self.tappedView.hidden = YES;
}

- (CardView *)cardViewForCard:(Card *)card
{
    __block CardView *cardViewForCard;
    
    [self.cardContainerView.subviews enumerateObjectsUsingBlock:^(CardView *cardView, NSUInteger idx, BOOL *stop) {
        if ([cardView.card isEqualToCard:card]) {
            cardViewForCard = cardView;
            *stop = YES;
        }
    }];
    
    return cardViewForCard;
}

- (void)updateWinsLabels
{
	NSString *format = @"%d Won";
    
	Player *player = [self.game playerAtPosition:PlayerPositionBottom];
	if (player) self.playerWinsBottomLabel.text = [NSString stringWithFormat:format, player.gamesWon];
    
	player = [self.game playerAtPosition:PlayerPositionLeft];
	if (player) self.playerWinsLeftLabel.text = [NSString stringWithFormat:format, player.gamesWon];
    
	player = [self.game playerAtPosition:PlayerPositionTop];
	if (player) self.playerWinsTopLabel.text = [NSString stringWithFormat:format, player.gamesWon];
    
	player = [self.game playerAtPosition:PlayerPositionRight];
	if (player) self.playerWinsRightLabel.text = [NSString stringWithFormat:format, player.gamesWon];
}

- (void)resizeLabelToFit:(UILabel *)label
{
	[label sizeToFit];
	CGRect rect = label.frame;
	rect.size.width = ceilf(rect.size.width/2.0f) * 2.0f;  // Make even
	rect.size.height = ceilf(rect.size.height/2.0f) * 2.0f;  // Make even
	label.frame = rect;
}

- (void)calculateLabelFrames
{
	UIFont *font = [UIFont rw_snapFontWithSize:14.0f];
	self.playerNameBottomLabel.font = font;
	self.playerNameLeftLabel.font = font;
	self.playerNameTopLabel.font = font;
	self.playerNameRightLabel.font = font;
    
	font = [UIFont rw_snapFontWithSize:11.0f];
	self.playerWinsBottomLabel.font = font;
	self.playerWinsLeftLabel.font = font;
	self.playerWinsTopLabel.font = font;
	self.playerWinsRightLabel.font = font;
    
	self.playerWinsBottomLabel.layer.cornerRadius = 4.0f;
	self.playerWinsLeftLabel.layer.cornerRadius = 4.0f;
	self.playerWinsTopLabel.layer.cornerRadius = 4.0f;
	self.playerWinsRightLabel.layer.cornerRadius = 4.0f;
    
	UIImage *image = [[UIImage imageNamed:@"ActivePlayer"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
	self.playerActiveBottomImageView.image = image;
	self.playerActiveLeftImageView.image = image;
	self.playerActiveTopImageView.image = image;
	self.playerActiveRightImageView.image = image;
    
	CGFloat viewWidth = self.view.bounds.size.width;
	CGFloat centerX = viewWidth / 2.0f;
    
	Player *player = [self.game playerAtPosition:PlayerPositionBottom];
    
	if (player) {
		self.playerNameBottomLabel.text = player.name;
        
		[self resizeLabelToFit:self.playerNameBottomLabel];
		CGFloat labelWidth = self.playerNameBottomLabel.bounds.size.width;
        
		CGPoint point = CGPointMake(centerX - 19.0f - 3.0f, 306.0f);
		self.playerNameBottomLabel.center = point;
        
		CGPoint winsPoint = point;
		winsPoint.x += labelWidth/2.0f + 6.0f + 19.0f;
		winsPoint.y -= 0.5f;
		self.playerWinsBottomLabel.center = winsPoint;
        
		self.playerActiveBottomImageView.frame = CGRectMake(0, 0, 20.0f + labelWidth + 6.0f + 38.0f + 2.0f, 20.0f);
        
		point.x = centerX - 9.0f;
		self.playerActiveBottomImageView.center = point;
	}
    
	player = [self.game playerAtPosition:PlayerPositionLeft];
    
	if (player) {
		self.playerNameLeftLabel.text = player.name;
        
		[self resizeLabelToFit:self.playerNameLeftLabel];
		CGFloat labelWidth = self.playerNameLeftLabel.bounds.size.width;
        
		CGPoint point = CGPointMake(2.0 + 20.0f + labelWidth/2.0f, 48.0f);
		self.playerNameLeftLabel.center = point;
        
		CGPoint winsPoint = point;
		winsPoint.x += labelWidth/2.0f + 6.0f + 19.0f;
		winsPoint.y -= 0.5f;
		self.playerWinsLeftLabel.center = winsPoint;
        
		self.playerActiveLeftImageView.frame = CGRectMake(2.0f, 38.0f, 20.0f + labelWidth + 6.0f + 38.0f + 2.0f, 20.0f);
	}
    
	player = [self.game playerAtPosition:PlayerPositionTop];
    
	if (player) {
		self.playerNameTopLabel.text = player.name;
        
		[self resizeLabelToFit:self.playerNameTopLabel];
		CGFloat labelWidth = self.playerNameTopLabel.bounds.size.width;
        
		CGPoint point = CGPointMake(centerX - 19.0f - 3.0f, 15.0f);
		self.playerNameTopLabel.center = point;
        
		CGPoint winsPoint = point;
		winsPoint.x += labelWidth/2.0f + 6.0f + 19.0f;
		winsPoint.y -= 0.5f;
		self.playerWinsTopLabel.center = winsPoint;
        
		self.playerActiveTopImageView.frame = CGRectMake(0, 0, 20.0f + labelWidth + 6.0f + 38.0f + 2.0f, 20.0f);
        
		point.x = centerX - 9.0f;
		self.playerActiveTopImageView.center = point;
	}
    
	player = [self.game playerAtPosition:PlayerPositionRight];
    
	if (player != nil) {
		self.playerNameRightLabel.text = player.name;
        
		[self resizeLabelToFit:self.playerNameRightLabel];
		CGFloat labelWidth = self.playerNameRightLabel.bounds.size.width;
        
		CGPoint point = CGPointMake(viewWidth - labelWidth/2.0f - 2.0f - 6.0f - 38.0f - 12.0f, 48.0f);
		self.playerNameRightLabel.center = point;
        
		CGPoint winsPoint = point;
		winsPoint.x += labelWidth/2.0f + 6.0f + 19.0f;
		winsPoint.y -= 0.5f;
		self.playerWinsRightLabel.center = winsPoint;
        
		self.playerActiveRightImageView.frame = CGRectMake(self.playerNameRightLabel.frame.origin.x - 20.0f, 38.0f, 20.0f + labelWidth + 6.0f + 38.0f + 2.0f, 20.0f);
	}
}

- (void)afterDealing
{
    [self.dealingCardsSound stop];
    self.snapButton.hidden = NO;
    [self.game beginRound];
}

#pragma mark - IBActions

- (IBAction)exitAction:(id)sender
{
    if (self.game.isServer) {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"End Game?" message:@"This will terminate the game for all other players." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [self.alertView show];
    } else {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Leave Game?" message:nil delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [self.alertView show];
    }
}

- (IBAction)turnOverPressed:(id)sender
{
    [self showTappedView];
}

- (IBAction)turnOverEnter:(id)sender
{
    [self showTappedView];
}

- (IBAction)turnOverExit:(id)sender
{
    [self hideTappedView];
}

- (IBAction)turnOverAction:(id)sender
{
    [self hideTappedView];
    [self.game turnCardForPlayerAtBottom];
}

- (IBAction)snapAction:(id)sender
{
}

- (IBAction)nextRoundAction:(id)sender
{
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self.game quitGameWithReason:QuitReasonUserQuit];
        
        // To cancel performSelector:afterDealing... if the user exits during dealing
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
}

#pragma mark - GameDelegate

- (void)gameWaitingForServerReady:(Game *)game
{
    self.centerLabel.text = @"Waiting for game to start...";
}

- (void)gameWaitingForClientsReady:(Game *)game
{
    self.centerLabel.text = @"Waiting for other players...";
}

- (void)gameDidBegin:(Game *)game
{
    [self showPlayerLabels];
    [self calculateLabelFrames];
    [self updateWinsLabels];
}

- (void)gameShouldDealCards:(Game *)game startingWithPlayer:(Player *)startingPlayer
{
    self.centerLabel.text = @"Dealing...";
    self.snapButton.hidden = YES;
    self.nextRoundButton.hidden = YES;
    NSTimeInterval delay = 1.0f;
    [self.dealingCardsSound performSelector:@selector(play) withObject:nil afterDelay:delay];
    
    for (int i = 0; i < 26; i++) {
        for (PlayerPosition p = startingPlayer.position; p < startingPlayer.position + 4; p++) {
            Player *player = [self.game playerAtPosition:p % 4];
            
            if (player && i < [startingPlayer.closedCards cardCount]) {
                CardView *cardView = [[CardView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CardWidth, CardHeight)];
                cardView.card = player.closedCards.cards[i];
                [self.cardContainerView addSubview:cardView];
                [cardView animateDealingToPlayer:player withDelay:delay];
                
                // Deal cards sequentially, not all at once
                delay += 0.1f;
            }
        }
    }
    
    [self performSelector:@selector(afterDealing) withObject:nil afterDelay:delay];
}

- (void)game:(Game *)game didActivatePlayer:(Player *)player
{
    [self showIndicatorForActivePlayer];
}

- (void)showIndicatorForActivePlayer
{
    [self hideActivePlayerIndicator];
    PlayerPosition position = [self.game activePlayer].position;
    
    switch (position) {
        case PlayerPositionBottom:
            self.playerActiveBottomImageView.hidden = NO;
            break;
            
        case PlayerPositionLeft:
            self.playerActiveLeftImageView.hidden = NO;
            break;
            
        case PlayerPositionTop:
            self.playerActiveTopImageView.hidden = NO;
            break;
            
        case PlayerPositionRight:
            self.playerActiveRightImageView.hidden = NO;
            break;
            
        default:
            break;
    }
    
    self.centerLabel.text = position == PlayerPositionBottom ? @"Your turn. Tap the stack." : [NSString stringWithFormat:@"%@'s turn", [self.game activePlayer].name];
}

- (void)game:(Game *)game player:(Player *)player turnedOverCard:(Card *)card
{
    [self.turnCardSound play];
    CardView *cardView = [self cardViewForCard:card];
    [cardView animateTurningOverForPlayer:player];
}

- (void)game:(Game *)game didRecycleCards:(NSArray *)recycledCards forPlayer:(Player *)player
{
    self.snapButton.enabled = NO;
    self.turnOverButton.enabled = NO;
    __block NSTimeInterval delay = 0.0f;
    
    [recycledCards enumerateObjectsUsingBlock:^(Card *card, NSUInteger idx, BOOL *stop) {
        CardView *cardView = [self cardViewForCard:card];
        [cardView animateRecycleForPlayer:player withDelay:delay];
        delay += 0.025f;
    }];
    
    [self performSelector:@selector(afterRecyclingCardsForPlayer:) withObject:player afterDelay:delay + 0.5f];
}

- (void)afterRecyclingCardsForPlayer:(Player *)player
{
    self.snapButton.enabled = YES;
    self.turnOverButton.enabled = YES;
    [self.game resumeAfterRecyclingCardsForPlayer:player];
}

- (void)game:(Game *)game playerDidDisconnect:(Player *)disconnectedPlayer redistributedCards:(NSDictionary *)redistributedCards
{
    [self hidePlayerLabelsForPlayer:disconnectedPlayer];
    [self hideActiveIndicatorForPlayer:disconnectedPlayer];
    [self hideSnapIndicatorForPlayer:disconnectedPlayer];
    
    for (PlayerPosition p = PlayerPositionBottom; p <= PlayerPositionRight; p++) {
        Player *otherPlayer = [self.game playerAtPosition:p];
        
        if (otherPlayer != disconnectedPlayer) {
            NSArray *cards = redistributedCards[otherPlayer.peerID];
            
            [cards enumerateObjectsUsingBlock:^(Card *card, NSUInteger idx, BOOL *stop) {
                // Is this necessary?
                CardView *cardView = [self cardViewForCard:card];
                cardView.card = card;
                
                [cardView animateCloseAndMoveFromPlayer:disconnectedPlayer toPlayer:otherPlayer withDelay:0.0f];
            }];
        }
    }
}

- (void)game:(Game *)game didQuitWithReason:(QuitReason)reason
{
    [self.delegate gameViewController:self didQuitWithReason:reason];
}

@end

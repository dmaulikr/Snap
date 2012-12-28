/*
 As noted in code comments, there are a few significant limitations that need to be fixed:
 1. The player who hosts the game has an advantage because they see everything a fraction of a second before the other players. This could be solved by delaying the animations on the server by the average “ping” time.
 2. The restriction that we put in to disable the Snap button after a player turns a card is also very unfair. That was done to avoid a problem with the networking, but it’s obviously not how you really should handle this.
 3. When a player calls Snap, if another player were to tap their closed stack, they would turn a card, which could invalidate the match
 */

@class MainViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainViewController *viewController;

@end

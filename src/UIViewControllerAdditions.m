#import "Three20/UIViewControllerAdditions.h"
#import "Three20/TTGlobal.h"
#import "Three20/TTURLRequestQueue.h"

static NSMutableDictionary* gSuperControllers = nil;
static NSMutableDictionary* gPopupViewControllers = nil;

@interface TTPopupView : UIView {
    UIViewController* _popupViewController;
}

@property(nonatomic,retain) UIViewController* popupViewController;

@end

@implementation TTPopupView

@synthesize popupViewController = _popupViewController;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _popupViewController = nil;
    }
    return self;
}

- (void)dealloc {
    [_popupViewController release];
    [super dealloc];
}

- (void)didAddSubview:(UIView*)subview {
//    TTDCONDITIONLOG(TTDFLAG_VIEWCONTROLLERS, @"ADD %@", subview);
}

- (void)willRemoveSubview:(UIView*)subview {
//    TTDCONDITIONLOG(TTDFLAG_VIEWCONTROLLERS, @"REMOVE %@", subview);
    [self removeFromSuperview];
}

@end


///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UIViewController (TTCategory)

// TTD TWEAK: Do this somewhere
// SwapMethods a new dealloc for UIViewController so it notifies us when it's going away.
// We need to remove dying controllers from our binding cache.
//TTSwapMethods([UIViewController class], @selector(dealloc), @selector(ttdealloc));

- (void)ttdealloc {
    self.superController = nil;
    self.popupViewController = nil;
    
    // Calls the original dealloc, swizzled away
    [self ttdealloc];
}


- (void)showNavigationBar:(BOOL)show animated:(BOOL)animated {
  if (animated) {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:TT_TRANSITION_DURATION];
  }

  self.navigationController.navigationBar.alpha = show ? 1 : 0;
  
  if (animated) {
    [UIView commitAnimations];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)canContainControllers {
    return NO;
}

- (UIViewController*)superController {
    UIViewController* parent = self.parentViewController;
    if (parent) {
        return parent;
    } else {
        NSString* key = [NSString stringWithFormat:@"%d", self.hash];
        return [gSuperControllers objectForKey:key];
    }
}

- (void)setSuperController:(UIViewController*)viewController {
    NSString* key = [NSString stringWithFormat:@"%d", self.hash];
    if (viewController) {
        if (!gSuperControllers) {
            gSuperControllers = TTCreateNonRetainingDictionary();
        }
        [gSuperControllers setObject:viewController forKey:key];
    } else {
        [gSuperControllers removeObjectForKey:key];
    }
}

- (UIViewController*)topSubcontroller {
    return nil;
}


- (UIViewController*)ttPreviousViewController {
  NSArray* viewControllers = self.navigationController.viewControllers;
  if (viewControllers.count > 1) {
    NSUInteger index = [viewControllers indexOfObject:self];
    if (index != NSNotFound) {
      return [viewControllers objectAtIndex:index-1];
    }
  }
  
  return nil;
}

- (UIViewController*)nextViewController {
  NSArray* viewControllers = self.navigationController.viewControllers;
  if (viewControllers.count > 1) {
    NSUInteger index = [viewControllers indexOfObject:self];
    if (index != NSNotFound && index+1 < viewControllers.count) {
      return [viewControllers objectAtIndex:index+1];
    }
  }
  return nil;
}

- (UIViewController*)popupViewController {
    NSString* key = [NSString stringWithFormat:@"%d", self.hash];
    return [gPopupViewControllers objectForKey:key];
}

- (void)setPopupViewController:(UIViewController*)viewController {
    NSString* key = [NSString stringWithFormat:@"%d", self.hash];
    if (viewController) {
        if (!gPopupViewControllers) {
            gPopupViewControllers = TTCreateNonRetainingDictionary();
        }
        [gPopupViewControllers setObject:viewController forKey:key];
    } else {
        [gPopupViewControllers removeObjectForKey:key];
    }
}

- (void)addSubcontroller:(UIViewController*)controller animated:(BOOL)animated
              transition:(UIViewAnimationTransition)transition {
    if (self.navigationController) {
        [self.navigationController addSubcontroller:controller animated:animated
                                         transition:transition];
    }
}

- (void)removeFromSupercontroller {
    [self removeFromSupercontrollerAnimated:YES];
}

- (void)removeFromSupercontrollerAnimated:(BOOL)animated {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:animated];
    }
}

- (void)bringControllerToFront:(UIViewController*)controller animated:(BOOL)animated {
}

- (NSString*)keyForSubcontroller:(UIViewController*)controller {
    return nil;
}

- (UIViewController*)subcontrollerForKey:(NSString*)key {
    return nil;
}

- (void)alert:(NSString*)message title:(NSString*)title delegate:(id)delegate {
  if (message) {
    UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:title message:message
      delegate:delegate cancelButtonTitle:TTLocalizedString(@"OK", @"") otherButtonTitles:nil]
      autorelease];
    [alert show];
  }
}

- (void)alert:(NSString*)message {
  [self alert:message title:TTLocalizedString(@"Alert", @"") delegate:nil];
}

- (void)alertError:(NSString*)message {
  [self alert:message title:TTLocalizedString(@"Error", @"") delegate:nil];
}

- (void)showBars:(BOOL)show animated:(BOOL)animated {
  [[UIApplication sharedApplication] setStatusBarHidden:!show animated:animated];
  
  [self showNavigationBar:show animated:animated];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UINavigationController (TTCategory)

- (void)pushAnimationDidStop {
  [TTURLRequestQueue mainQueue].suspended = NO;
}

- (void)pushViewController:(UIViewController*)controller
    animatedWithTransition:(UIViewAnimationTransition)transition {
  [TTURLRequestQueue mainQueue].suspended = YES;

  [self pushViewController:controller animated:NO];
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:TT_FLIP_TRANSITION_DURATION];
  [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(pushAnimationDidStop)];
  [UIView setAnimationTransition:transition forView:self.view cache:YES];
  [UIView commitAnimations];
}

- (void)popViewControllerAnimatedWithTransition:(UIViewAnimationTransition)transition {
  [TTURLRequestQueue mainQueue].suspended = YES;

  [self popViewControllerAnimated:NO];
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:TT_FLIP_TRANSITION_DURATION];
  [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(pushAnimationDidStop)];
  [UIView setAnimationTransition:transition forView:self.view cache:YES];
  [UIView commitAnimations];
}

@end

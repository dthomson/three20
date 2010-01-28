#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIViewController (TTCategory)

/**
 * The view controller that comes before this one in a navigation controller's history.
 */
- (UIViewController*)ttPreviousViewController;

/**
 * The view controller that comes after this one in a navigation controller's history.
 */
- (UIViewController*)nextViewController;

/**
 * A popup view controller that is presented on top of this view controller. 
 */
@property(nonatomic,retain) UIViewController* popupViewController;


/**
 * Determines whether a controller is primarily a container of other controllers.
 */
@property(nonatomic,readonly) BOOL canContainControllers;

/**
 * The view controller that contains this view controller.
 *
 * This is just like parentViewController, except that it is not readonly.  This property offers
 * custom UIViewController subclasses the chance to tell TTNavigator how to follow the hierarchy
 * of view controllers.
 */
@property(nonatomic,retain) UIViewController* superController;

/**
 * Shows a UIAlertView with a message and title.
 *
 * @delegate A UIAlertView delegate
 */ 
- (void)alert:(NSString*)message title:(NSString*)title delegate:(id)delegate;

/**
 * Shows a UIAlertView with a message.
 */ 
- (void)alert:(NSString*)message;

/**
 * Shows a UIAlertView with an error message.
 */ 
- (void)alertError:(NSString*)message;

/**
 * Dismisses a view controller using the opposite transition it was presented with.
 */
- (void)removeFromSupercontroller;
- (void)removeFromSupercontrollerAnimated:(BOOL)animated;

/**
 * Gets a key that can be used to identify a subcontroller in subcontrollerForKey.
 */
- (NSString*)keyForSubcontroller:(UIViewController*)controller;

/**
 * Gets a subcontroller with the key that was returned from keyForSubcontroller.
 */
- (UIViewController*)subcontrollerForKey:(NSString*)key;

/**
 * Shows or hides the navigation and status bars.
 */
- (void)showBars:(BOOL)show animated:(BOOL)animated;

@end

@interface UINavigationController (TTCategory)

/**
 * Pushes a view controller with a transition other than the standard sliding animation.
 */
- (void)pushViewController:(UIViewController*)controller
        animatedWithTransition:(UIViewAnimationTransition)transition;

/**
 * Pops a view controller with a transition other than the standard sliding animation.
 */
- (void)popViewControllerAnimatedWithTransition:(UIViewAnimationTransition)transition;

@end

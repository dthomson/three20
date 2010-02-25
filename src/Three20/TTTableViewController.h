#import "Three20/TTViewController.h"
#import "Three20/TTTableViewDataSource.h"

@class TTActivityLabel;

@interface TTTableViewController : TTViewController <TTTableViewDataSourceDelegate> {
  UITableView* _tableView;
  UIView* _tableBannerView;
  UIView* _tableOverlayView;
  TTActivityLabel* _refreshingView;
  UIView* _menuView;
  UITableViewCell* _menuCell;
  id<TTTableViewDataSource> _dataSource;
  id<TTTableViewDataSource> _statusDataSource;
  id<UITableViewDelegate> _tableDelegate;
  NSTimer* _bannerTimer;
  UITableViewStyle _tableViewStyle;
  UIInterfaceOrientation _lastInterfaceOrientation;
  BOOL _variableHeightRows;
}

@property(nonatomic,retain) UITableView* tableView;
@property(nonatomic,readonly) UIView* menuView;

@property(nonatomic,retain) id<TTTableViewDataSource> dataSource;
@property(nonatomic) BOOL variableHeightRows;

- (id<TTTableViewDataSource>)createDataSource;
- (id<UITableViewDelegate>)createDelegate;

/**
 * Shows a menu over a table cell.
 */
- (void)showMenu:(UIView*)view forCell:(UITableViewCell*)cell animated:(BOOL)animated;

/**
 * Hides the currently visible table cell menu.
 */
- (void)hideMenu:(BOOL)animated;

- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath*)indexPath;
- (BOOL)shouldNavigateToURL:(NSString*)URL;

- (void)didBeginDragging;
- (void)didEndDragging;

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;

@end

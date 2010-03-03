#import "Three20/TTTableViewController.h"
#import "Three20/TTTableViewDataSource.h"
#import "Three20/TTTableView.h"
#import "Three20/TTTableItem.h"
#import "Three20/TTTableItemCell.h"
#import "Three20/TTActivityLabel.h"
#import "Three20/TTTableViewDelegate.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static const CGFloat kRefreshingViewHeight = 22;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTTableViewController

@synthesize tableView = _tableView, dataSource = _dataSource,
            variableHeightRows = _variableHeightRows,  menuView = _menuView;

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)updateTableDelegate {
  if (!_tableView.delegate) {
    [_tableDelegate release];
    _tableDelegate = [[self createDelegate] retain];
    
      // You need to set it to nil before changing it or it won't have any effect
    _tableView.delegate = nil;
    _tableView.delegate = _tableDelegate;
  }
}

- (void)reloadTableData {
  [self updateTableDelegate];
  //NSDate* date = [NSDate date];
  [_tableView reloadData];
  //NSLog(@"TABLE LAYOUT %fs", [date timeIntervalSinceNow]);
}

- (void)refreshingHideAnimationStopped {
  [_refreshingView removeFromSuperview];
  [_refreshingView release];
  _refreshingView = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
  if (self = [super init]) {
    _tableView = nil;
    _refreshingView = nil;
    _dataSource = nil;
    _statusDataSource = nil;
    _tableDelegate = nil;
    _menuView = nil;
    _menuCell = nil;
    _bannerTimer = nil;
    _variableHeightRows = NO;
    _lastInterfaceOrientation = self.interfaceOrientation;
  }  
  return self;
}

- (void)dealloc {
  _tableView.delegate = nil;
  _tableView.dataSource = nil;
  TT_RELEASE_SAFELY(_tableDelegate);
  [_dataSource.delegates removeObject:self];
  TT_RELEASE_SAFELY(_dataSource);
  TT_RELEASE_SAFELY(_tableView);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:NO];

  if ([_tableView isKindOfClass:[TTTableView class]]) {
    TTTableView* tableView = (TTTableView*)_tableView;
    tableView.highlightedLabel = nil;    
  }
}  

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTViewController

- (void)persistView:(NSMutableDictionary*)state {
  CGFloat scrollY = _tableView.contentOffset.y;
  [state setObject:[NSNumber numberWithFloat:scrollY] forKey:@"scrollOffsetY"];
}

- (void)restoreView:(NSDictionary*)state {
  NSNumber* scrollY = [state objectForKey:@"scrollOffsetY"];
  _tableView.contentOffset = CGPointMake(0, scrollY.floatValue);
}

- (void)reloadContent {
  [_dataSource load:TTURLRequestCachePolicyNetwork nextPage:NO];
}

- (void)refreshContent {
  if (!_dataSource.isLoading && _dataSource.isOutdated) {
    [self reloadContent];
  }
}

- (void)updateView {
  self.dataSource = [self createDataSource];
  
  if (_dataSource.isLoading) {
    if (_dataSource.isLoadingMore) {
      [self invalidateViewState:(_viewState & TTViewDataStates) | TTViewLoadingMore];
    } else if (_dataSource.isLoaded) {
      [self invalidateViewState:(_viewState & TTViewDataStates) | TTViewRefreshing];
    } else {
      [self invalidateViewState:TTViewLoading];
    }
  } else if (!_dataSource.isLoaded) {
    [_dataSource load:TTURLRequestCachePolicyDefault nextPage:NO];
  } else {
    if (_contentError) {
      [self invalidateViewState:TTViewDataLoadedError];
    } else if (_dataSource.isEmpty) {
      [self invalidateViewState:TTViewEmpty];
    } else {
      [self invalidateViewState:TTViewDataLoaded];
    }
  }
}

- (void)updateLoadingView {
  if (self.viewState & TTViewLoading) {
    NSString* title = [self titleForActivity];
    TTTableStatusItem* statusItem = [TTTableActivityItem itemWithText:title];
    statusItem.sizeToFit = YES;

    _statusDataSource = [[TTListDataSource alloc] initWithItems:
      [NSArray arrayWithObject:statusItem]];
    _tableView.dataSource = _statusDataSource;
    [self reloadTableData];
  }
  
  if (self.viewState & TTViewRefreshing) {
    if (!_refreshingView) {
      _refreshingView = [[TTActivityLabel alloc] initWithFrame:
        CGRectMake(0, _tableView.height, self.view.width, kRefreshingViewHeight)
        style:TTActivityLabelStyleBlackBox text:[self titleForActivity]];
      _refreshingView.centeredToScreen = NO;
      _refreshingView.userInteractionEnabled = NO;
      _refreshingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
      _refreshingView.font = [UIFont boldSystemFontOfSize:12];
      
      NSInteger tableIndex = [self.view.subviews indexOfObject:_tableView];
      [self.view insertSubview:_refreshingView atIndex:tableIndex+1];
      
      [UIView beginAnimations:nil context:nil];
      [UIView setAnimationDuration:TT_TRANSITION_DURATION];
      [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
      _refreshingView.frame = CGRectOffset(_refreshingView.frame, 0, -kRefreshingViewHeight);
      [UIView commitAnimations];
    }
  } else if (_refreshingView) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:TT_TRANSITION_DURATION*2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(refreshingHideAnimationStopped)];
    _refreshingView.alpha = 0;
    [UIView commitAnimations];
  }
}

- (void)updateDataView {
  if (self.viewState & TTViewDataLoaded) {
    [_statusDataSource release];
    _statusDataSource = nil;

    if (_dataSource) {
      _tableView.dataSource = _dataSource;
    } else if ([self conformsToProtocol:@protocol(UITableViewDataSource)]) {
      _tableView.dataSource = (id<UITableViewDataSource>)self;
    } else {
      _tableView.dataSource = nil;
    }
  } else if (self.viewState & TTViewDataLoadedError) {
    NSString* title = [self titleForError:_contentError];
    NSString* subtitle = [self subtitleForError:_contentError];
    UIImage* image = [self imageForError:_contentError];
    
    TTTableErrorItem* statusItem = [TTTableErrorItem itemWithTitle:title subtitle:subtitle
                                                     image:image];
    statusItem.sizeToFit = YES;

    _statusDataSource = [[TTListDataSource alloc] initWithItems:
      [NSArray arrayWithObject:statusItem]];
    _tableView.dataSource = _statusDataSource;
  } else if (!(self.viewState & TTViewLoadingStates)) {
    NSString* title = [self titleForNoData];
    NSString* subtitle = [self subtitleForNoData];
    UIImage* image = [self imageForNoData];
    
    TTTableStatusItem* statusItem = [TTTableErrorItem itemWithTitle:title subtitle:subtitle
                                                      image:image];
    statusItem.sizeToFit = YES;

    _statusDataSource = [[TTListDataSource alloc] initWithItems:
      [NSArray arrayWithObject:statusItem]];
    _tableView.dataSource = _statusDataSource;
  }

  [self reloadTableData];
}

- (void)unloadView {
  [_dataSource.delegates removeObject:self];
  [_dataSource release];
  _dataSource = nil;
  [_statusDataSource release];
  _statusDataSource = nil;
  [_tableView release];
  _tableView = nil;
  [_refreshingView release];
  _refreshingView = nil;
  [super unloadView];
}

- (void)keyboardWillAppear:(BOOL)animated {
  [self.tableView scrollFirstResponderIntoView];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTTableViewDataSourceDelegate

- (void)dataSourceDidStartLoad:(id<TTTableViewDataSource>)dataSource {
  if (dataSource.isLoadingMore) {
    [self invalidateViewState:(_viewState & TTViewDataStates) | TTViewLoadingMore];
  } else if (_viewState & TTViewDataStates) {
    [self invalidateViewState:(_viewState & TTViewDataStates) | TTViewRefreshing];
  } else {
    [self invalidateViewState:TTViewLoading];
  }
}

- (void)dataSourceDidFinishLoad:(id<TTTableViewDataSource>)dataSource {
  if (dataSource.isEmpty) {
    [self invalidateViewState:TTViewEmpty];
  } else {
    [self invalidateViewState:TTViewDataLoaded];
  }
}

- (void)dataSource:(id<TTTableViewDataSource>)dataSource didFailLoadWithError:(NSError*)error {
  self.contentError = error;
  [self invalidateViewState:TTViewDataLoadedError];
}

- (void)dataSourceDidCancelLoad:(id<TTTableViewDataSource>)dataSource {
  [self invalidateViewState:TTViewDataLoadedError];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (void)setDataSource:(id<TTTableViewDataSource>)dataSource {
  if (dataSource != _dataSource) {
    [_dataSource.delegates removeObject:self];
    [_dataSource release];
    _dataSource = [dataSource retain];
    [_dataSource.delegates addObject:self];
  }
}

- (id<TTTableViewDataSource>)createDataSource {
  return nil;
}

- (id<UITableViewDelegate>)createDelegate {
  if (_variableHeightRows) {
    return [[[TTTableViewVarHeightDelegate alloc] initWithController:self] autorelease];
  } else {
    return [[[TTTableViewDelegate alloc] initWithController:self] autorelease];
  }
}

- (void)showMenu:(UIView*)view forCell:(UITableViewCell*)cell animated:(BOOL)animated {
    [self hideMenu:YES];
    
    _menuView = [view retain];
    _menuCell = [cell retain];
    
    // Insert the cell below all content subviews
    [_menuCell.contentView insertSubview:_menuView atIndex:0];
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:TT_FAST_TRANSITION_DURATION];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    }
    
    // Move each content subview down, revealing the menu
    for (UIView* view in _menuCell.contentView.subviews) {
        if (view != _menuView) {
            view.left -= _menuCell.contentView.width;
        }
    }
    
    if (animated) {
        [UIView commitAnimations];
    }
}

- (void)hideMenu:(BOOL)animated {
    if (_menuView) {
        if (animated) {
            [UIView beginAnimations:nil context:_menuView];
            [UIView setAnimationDuration:TT_FAST_TRANSITION_DURATION];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(hideMenuAnimationDidStop:finished:context:)];
        }
        
        for (UIView* view in _menuCell.contentView.subviews) {
            if (view != _menuView) {
                view.left += _menuCell.contentView.width;
            }
        }
        
        if (animated) {
            [UIView commitAnimations];
        } else {
            [_menuView removeFromSuperview];
        }
        
        TT_RELEASE_SAFELY(_menuView);
        TT_RELEASE_SAFELY(_menuCell);
    }
}

- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
}

- (BOOL)shouldNavigateToURL:(NSString*)URL {
  return YES;
}

- (void)didBeginDragging {
}

- (void)didEndDragging {
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
}

@end

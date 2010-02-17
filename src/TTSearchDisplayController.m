//
// Copyright 2009 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Three20/TTSearchDisplayController.h"

#import "Three20/TTGlobal.h"

#import "Three20/TTTableViewController.h"
#import "Three20/TTTableViewDataSource.h"
#import "Three20/TTDefaultStyleSheet.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

//static const NSTimeInterval kPauseInterval = 0.4;
static const NSTimeInterval kPauseInterval = 4.0;

static const NSString *MMSearchSelectorKey = @"MMSearchScopeSelectorKey";
static const NSString *MMSearchScopeOptionKey = @"MMSearchScopeOptionKey";
static const NSString *MMSearchPauseDelayKey = @"MMSearchPauseDelayKey";


///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTSearchDisplayController

@synthesize searchResultsViewController = _searchResultsViewController,
            pausesBeforeSearching = _pausesBeforeSearching;

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)resetResults {
  if (_searchResultsViewController.dataSource.isLoading) {
    [_searchResultsViewController.dataSource cancel];
  }

  [_searchResultsViewController.dataSource invalidate:YES];
  [_searchResultsViewController.dataSource search:nil];
  [_searchResultsViewController viewWillDisappear:NO];
  [_searchResultsViewController viewDidDisappear:NO];
// XXX: Disable for now b/c of crash
//  _searchResultsViewController.tableView = nil;
//  [_searchResultsViewController invalidateView];
}

- (void)restartPauseTimerWithInfo:(NSDictionary *)userInfo {
    TT_INVALIDATE_TIMER(_pauseTimer);
    _pauseTimer = [NSTimer scheduledTimerWithTimeInterval:kPauseInterval target:self
                                                 selector:@selector(searchAfterPause) userInfo:userInfo repeats:NO];
}

- (void)restartPauseTimer {
    [self restartPauseTimerWithInfo:nil];
}


- (void)searchAfterPause {    
    // Parse the timer userIfno
    NSDictionary *userInfo = _pauseTimer.userInfo;
    NSString *searchSelectorString = [userInfo objectForKey:MMSearchSelectorKey];
    NSNumber *searchOption = [userInfo objectForKey:MMSearchScopeOptionKey];

    // Timer is done
    _pauseTimer = nil;

    // Do the correct search
    if (searchSelectorString) {
        SEL searchSelector = NSSelectorFromString(searchSelectorString);
        
        // Default if we don't respond to the search selector
        if ([_searchResultsViewController.dataSource respondsToSelector:searchSelector] == NO) {
            [_searchResultsViewController.dataSource search:self.searchBar.text];
            return;
        }
        
        if ([searchSelectorString isEqual:@"search:"]) {
            [_searchResultsViewController.dataSource search:self.searchBar.text];
        }
        else if ([searchSelectorString isEqual:@"search:searchScope:"]) {
            
            [_searchResultsViewController.dataSource performSelector:searchSelector withObject:self.searchBar.text withObject:searchOption];
        }
    }
    // Default if we don't have the search selector
    else {
        [_searchResultsViewController.dataSource search:self.searchBar.text];
        return;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithSearchBar:(UISearchBar*)searchBar contentsController:(UIViewController*)controller {
  if (self = [super initWithSearchBar:searchBar contentsController:controller]) {
    _searchResultsDelegate2 = nil;
    _searchResultsViewController = nil;
    _pauseTimer = nil;
    _pausesBeforeSearching = NO;
    
    self.delegate = self;
  }
  return self;
}

- (void)dealloc {
  TT_INVALIDATE_TIMER(_pauseTimer);
  TT_RELEASE_SAFELY(_searchResultsDelegate2);
  TT_RELEASE_SAFELY(_searchResultsViewController);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UISearchDisplayDelegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController*)controller {
  self.searchContentsController.navigationItem.rightBarButtonItem.enabled = NO;
  UIView* backgroundView = [self.searchBar viewWithTag:TT_SEARCH_BAR_BACKGROUND_TAG];
  if (backgroundView) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:TT_FAST_TRANSITION_DURATION];
    backgroundView.alpha = 0;
    [UIView commitAnimations];
  }
  originalSearchBarBounds = controller.searchBar.bounds;
  originalSearchBarCenter = controller.searchBar.center;
    
    TTLOGRECT(originalSearchBarBounds);
    
  controller.searchBar.left = 0;
    
//  if (!self.searchContentsController.navigationController) {
//    [UIView beginAnimations:nil context:nil];
//    self.searchBar.superview.top -= self.searchBar.screenY - TTStatusHeight();
//    [UIView commitAnimations];
//  }
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController*)controller {
  // XXX: Moved vaildateView to -searchDisplayController:didLoadSearchResultsTableView
  [_searchResultsViewController validateView];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController*)controller {
  self.searchContentsController.navigationItem.rightBarButtonItem.enabled = YES;
  
  UIView* backgroundView = [self.searchBar viewWithTag:TT_SEARCH_BAR_BACKGROUND_TAG];
  if (backgroundView) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:TT_FAST_TRANSITION_DURATION];
    backgroundView.alpha = 1;
    [UIView commitAnimations];
  }
    
//  if (!self.searchContentsController.navigationController) {
//    [UIView beginAnimations:nil context:nil];
//    self.searchBar.superview.top += self.searchBar.top - TTStatusHeight();
//    [UIView commitAnimations];
//  }
}
 
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController*)controller {    
  [self resetResults];
    
    NSLog(@"width before %f after %f", controller.searchBar.width, originalSearchBarBounds.size.width);
    
    controller.searchBar.width = originalSearchBarBounds.size.width;
    controller.searchBar.height = originalSearchBarBounds.size.height;

//    [UIView beginAnimations:nil context:nil];
    controller.searchBar.centerX = originalSearchBarCenter.x;
    controller.searchBar.centerY = originalSearchBarCenter.y;
//    [UIView commitAnimations];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller
        didLoadSearchResultsTableView:(UITableView *)tableView {
    tableView.backgroundColor = TTSTYLEVAR(backgroundColor);
    tableView.separatorColor = TTSTYLEVAR(tableSeparatorColor);   
    _searchResultsViewController.tableView = tableView;
    [_searchResultsViewController validateView];
}
 
- (void)searchDisplayController:(UISearchDisplayController *)controller
        willUnloadSearchResultsTableView:(UITableView *)tableView {
    _searchResultsViewController.tableView = nil;
    [_searchResultsViewController invalidateView];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
  [_searchResultsViewController viewWillAppear:NO];
  [_searchResultsViewController viewDidAppear:NO];
}

- (void)searchDisplayController:(UISearchDisplayController*)controller
        willHideSearchResultsTableView:(UITableView*)tableView {
  [self resetResults];
}

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller
        shouldReloadTableForSearchString:(NSString*)searchString {
  if (_pausesBeforeSearching) {
    [self restartPauseTimer];
  } else {
    [_searchResultsViewController.dataSource invalidate:YES];
    [_searchResultsViewController.dataSource search:searchString];
    [_searchResultsViewController invalidateView];
  }
  // XXX: Was NO before
  return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller
        shouldReloadTableForSearchScope:(NSInteger)searchOption {
    // XXX: Tweaked here b/c we don't have TTModel
    [_searchResultsViewController.dataSource invalidate:YES];
    
    // Pack the search option into an object
    NSNumber *searchOptionObject = [NSNumber numberWithInteger:searchOption];
    
    // Determine the search delay
    NSNumber *searchDelay = [NSNumber numberWithDouble:3.0];
    
    if (_pausesBeforeSearching) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:searchOptionObject, MMSearchScopeOptionKey, NSStringFromSelector(@selector(search:searchScope:)), MMSearchSelectorKey, searchDelay, MMSearchPauseDelayKey, nil]; 
        [self restartPauseTimerWithInfo:userInfo];
    } 
    else {
        SEL scopedSearch = @selector(search:searchScope:);
        
        if ([_searchResultsViewController.dataSource respondsToSelector:scopedSearch]) {
            [_searchResultsViewController.dataSource performSelector:scopedSearch withObject:self.searchBar.text withObject:searchOptionObject];
        }
        else {
            [_searchResultsViewController.dataSource search:self.searchBar.text];
        }

        [_searchResultsViewController invalidateView];
    }

    // XXX: Was NO before
    return YES;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (void)setSearchResultsDelegate:(id<UITableViewDelegate>)searchResultsDelegate {
  [super setSearchResultsDelegate:searchResultsDelegate];
  if (_searchResultsDelegate2 != searchResultsDelegate) {
    [_searchResultsDelegate2 release];
    _searchResultsDelegate2 = [searchResultsDelegate retain];
  }
}

@end

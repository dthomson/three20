#import "Three20/TTTableViewCell.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTTableViewCell

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForItem:(id)item {
  return TT_ROW_HEIGHT;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

//- (void)dealloc {
//  [super dealloc];
//}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewCell

- (void)prepareForReuse {
  self.object = nil;
  [super prepareForReuse];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (id)object {
  return nil;
}

- (void)setObject:(id)object {
}

@end

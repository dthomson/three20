#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (TTCategory)

/**
 * Determines if the string contains only whitespace.
 */ 
- (BOOL)isWhitespace;

/**
 * Determines if the string is empty or contains only whitespace.
 */ 
- (BOOL)isEmptyOrWhitespace;

/**
 * Parses a URL query string into a dictionary.
 */
- (NSDictionary*)queryDictionaryUsingEncoding:(NSStringEncoding)encoding;

/**
 * Returns a string with all HTML tags removed.
 */
- (NSString*)stringByRemovingHTMLTags;

@end

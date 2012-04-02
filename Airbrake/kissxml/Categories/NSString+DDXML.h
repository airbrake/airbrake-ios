#import <Foundation/Foundation.h>
#import <libxml/tree.h>


@interface NSString (DDXML)

/**
 * xmlChar - A basic replacement for char, a byte in a UTF-8 encoded string.
**/
- (const xmlChar *)ddxml_xmlChar;

- (NSString *)ddxml_stringByTrimming;

@end

#import "NSString+DDXML.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@implementation NSString (DDXML)

- (const xmlChar *)ddxml_xmlChar
{
	return (const xmlChar *)[self UTF8String];
}

#ifdef GNUSTEP
- (NSString *)ddxml_stringByTrimming
{
	return [self stringByTrimmingSpaces];
}
#else
- (NSString *)ddxml_stringByTrimming
{
	NSMutableString *mStr = [self mutableCopy];
	CFStringTrimWhitespace((__bridge CFMutableStringRef)mStr);
	
	NSString *result = [mStr copy];
	
	return result;
}
#endif

@end

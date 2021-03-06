#import "MPEdnWriterTests.h"

#import "MPEdnWriter.h"
#import "MPEdnSymbol.h"

#define MPAssertSerialisesOK(value, correct)             \
{                                                        \
  MPEdnWriter *writer = [MPEdnWriter new];               \
                                                         \
  NSString *str = [writer serialiseToEdn: value];        \
                                                         \
  STAssertEqualObjects (str, correct, @"Serialise");     \
}

@implementation MPEdnWriterTests

- (void) testNumbers
{
  MPAssertSerialisesOK (@1, @"1");
  MPAssertSerialisesOK (@-1, @"-1");
  
  MPAssertSerialisesOK ([NSNumber numberWithShort: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithInt: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithUnsignedInt: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithLong: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithLongLong: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithUnsignedLongLong: 1234], @"1234");
  
  MPAssertSerialisesOK ([NSNumber numberWithDouble: 1.1], @"1.100000000000000E+00");
  MPAssertSerialisesOK ([NSNumber numberWithFloat: 1.1], @"1.1000000E+00");
  MPAssertSerialisesOK (@1.1e-5, @"1.100000000000000E-05");
  
  // boolean
  MPAssertSerialisesOK (@YES, @"true");
  MPAssertSerialisesOK (@NO, @"false");
  
  // characters
  // NSNumber is pretty broken wrt characters. [NSNumber numberWithChar: 'a']
  // produces a number that is reported as a character, but '\n' doesn't. As
  // as workaround, you can force a number to be seen as a character using
  // MPEdnTagAsCharacter. See discussion here:
  // http://www.cocoabuilder.com/archive/cocoa/136956-nsnumber-is-completely-broken.html
  MPAssertSerialisesOK (@'a', @"\\a");

  //  NSLog (@"********** %s", [[NSNumber numberWithChar: '\n'] objCType]);
  //  NSLog (@"********** %@", [[NSNumber numberWithChar: '\n'] class]);
  //  NSLog (@"********** %li", CFNumberGetType ((CFNumberRef)[NSNumber numberWithChar: '\n']));

  {
    NSNumber *newline = MPEdnTagAsCharacter ([NSNumber numberWithChar: '\n']);
    MPAssertSerialisesOK (newline, @"\\\n");
  }
}

- (void) testStrings
{
  MPAssertSerialisesOK (@"", @"\"\"");
  MPAssertSerialisesOK (@"hello", @"\"hello\"");
  MPAssertSerialisesOK (@"a \n in it", @"\"a \\n in it\"");
  MPAssertSerialisesOK (@"a \" in it", @"\"a \\\" in it\"");
  MPAssertSerialisesOK (@"a \" and a \\ in it", @"\"a \\\" and a \\\\ in it\"");
  MPAssertSerialisesOK (@"\\", @"\"\\\\\"");
  MPAssertSerialisesOK (@"\\\"", @"\"\\\\\\\"\"");
  MPAssertSerialisesOK (@"\\ abc", @"\"\\\\ abc\"");
  MPAssertSerialisesOK (@"abc \\", @"\"abc \\\\\"");
  MPAssertSerialisesOK (@"abc \\e", @"\"abc \\\\e\"");
  MPAssertSerialisesOK (@"a\\", @"\"a\\\\\"");
  
  MPAssertSerialisesOK (@"line 1\nline 2", @"\"line 1\\nline 2\"");
  MPAssertSerialisesOK (@"line 1\r\nline 2", @"\"line 1\\r\\nline 2\"");
  
  STAssertEqualObjects ([@{@"a" : @1} objectToEdnString], @"{:a 1}", @"Test category");  
}

- (void) testNil
{
  MPAssertSerialisesOK (nil, @"nil");
  MPAssertSerialisesOK ([NSNull null], @"nil");
}

- (void) testMaps
{
  MPAssertSerialisesOK (@{}, @"{}");
  MPAssertSerialisesOK (@{@"a" : @1}, @"{:a 1}");
  MPAssertSerialisesOK (@{@"a non keyword" : @1}, @"{\"a non keyword\" 1}");
  
  {
    MPEdnWriter *writer = [MPEdnWriter new];
    writer.useKeywordsInMaps = NO;

    STAssertEqualObjects ([writer serialiseToEdn: @{@"a" : @1}], @"{\"a\" 1}", @"Serialise");
  }
}

- (void) testLists
{
  MPAssertSerialisesOK (@[], @"[]");
  MPAssertSerialisesOK (@[@1], @"[1]");
  
  {
    NSArray *list = @[@"hello", @1];
    MPAssertSerialisesOK (list, @"[\"hello\",1]");
  }
}

- (void) testSets
{
  {
    NSSet *set = [NSSet set];
    MPAssertSerialisesOK (set, @"#{}");
  }
  
  {
    NSSet *set = [NSSet setWithArray: @[@1, @"a"]];
    MPAssertSerialisesOK (set, @"#{\"a\",1}");
  }
}

- (void) testSymbols
{
  MPAssertSerialisesOK ([MPEdnSymbol symbolWithName: @"my-symbol"], @"my-symbol");
}

- (void) testKeywords
{
  MPAssertSerialisesOK (@{@"abc" : @1}, @"{:abc 1}");
  MPAssertSerialisesOK (@{@"e4faee275bb1740e2001d285a052474300c6921a" : @1}, @"{:e4faee275bb1740e2001d285a052474300c6921a 1}");
}

@end

//
//  Copyright (c) 2013 feedtailor Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "FTZipTest.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self performSelector:@selector(doTest) withObject:nil afterDelay:0];
}

-(void) doTest
{
    NSString *documentDirectory = [@"~/Desktop/" stringByExpandingTildeInPath];
    [FTZipTest unzipTestWithDirectory:[documentDirectory stringByAppendingPathComponent:@"unzip"]];
    [FTZipTest zipTestWithDirectory:[documentDirectory stringByAppendingPathComponent:@"zip"]];
}

@end

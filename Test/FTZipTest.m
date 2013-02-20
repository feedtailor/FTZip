//
//  Copyright (c) 2013 feedtailor Inc. All rights reserved.
//

#import "FTZipTest.h"
#import "FTZip.h"

@implementation FTZipTest

+(void) unzipTestWithDirectory:(NSString*)destination
{
	NSLog(@"dir> %@", destination);
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	[fileManager removeItemAtPath:destination error:NULL];
    
	FTZipUnzip *unzip;
	BOOL result;
	
    //	FTCharacterEncodingTool* tool = [[FTCharacterEncodingTool alloc] init];
	id tool = nil;
    
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	result = [unzip writeToPath:destination overWrite:YES];
	NSLog(@"result: %d", result);
	
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	result = [unzip writeToPath:destination overWrite:NO];
	NSLog(@"result: %d", result);
	
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample_password" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	unzip.password = @"wrong";
	result = [unzip writeToPath:destination overWrite:YES];
	NSLog(@"result: %d (%@)", result, [unzip.error description]);
	
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample_password" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	unzip.password = @"hoge"; // correct password
	result = [unzip writeToPath:destination overWrite:YES];
	NSLog(@"result: %d", result);
    
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample_broken" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	result = [unzip writeToPath:destination overWrite:YES];
	NSLog(@"result: %d", result);
	
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dummy" ofType:@"jpeg"]];
	unzip.pathEncodingDetector = tool;
	result = [unzip writeToPath:destination overWrite:YES];
	NSLog(@"result: %d", result);
	
	[fileManager removeItemAtPath:destination error:NULL];
    
	NSMutableArray* arr = [NSMutableArray array];
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	NSArray* paths = [unzip contentPaths];
	for (NSString* path in paths) {
		NSLog(@"%@", path);
	}
    
	for (int i = 0; i < [paths count]; i+= 2) {
		[arr addObject:[paths objectAtIndex:i]];
	}
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	result = [unzip write:arr toPath:destination overWrite:YES];
	NSLog(@"result: %d", result);
	
	[arr removeAllObjects];
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample_password" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	paths = [unzip contentPaths];
	NSLog(@"%@", paths);
    
	for (int i = 0; i < [paths count]; i+= 2) {
		[arr addObject:[paths objectAtIndex:i]];
	}
	unzip = [[FTZipUnzip alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sample_password" ofType:@"zip"]];
	unzip.pathEncodingDetector = tool;
	result = [unzip write:arr toPath:destination overWrite:YES];
	NSLog(@"result: %d (%@)", result, [unzip.error description]);
}

+(void) zipTestWithDirectory:(NSString*)destination
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
	[fileManager removeItemAtPath:destination error:NULL];
	[fileManager createDirectoryAtPath:destination withIntermediateDirectories:YES attributes:nil error:nil];
	
	FTZipZip* zip = nil;
	NSData* d = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dummy" ofType:@"jpeg"]];
	zip = [[FTZipZip alloc] initWithData:d filename:@"dummy.jpeg"];
//	zip.password = @"test";
	BOOL result = [zip writeToPath:[destination stringByAppendingPathComponent:@"jpeg.zip"] append:NO];
	NSLog(@"%d", result);
    
    NSMutableArray* paths = [NSMutableArray array];
    [paths addObject:[[NSBundle mainBundle] pathForResource:@"dummy" ofType:@"jpeg"]];
    [paths addObject:[[NSBundle mainBundle] pathForResource:@"Sample" ofType:@"zip"]];
    [paths addObject:[[NSBundle mainBundle] pathForResource:@"Sample_password" ofType:@"zip"]];
    zip = [[FTZipZip alloc] initWithContentsOfFiles:paths basePath:[[paths lastObject] stringByDeletingLastPathComponent]];
    //	zip.password = @"test";
	result = [zip writeToPath:[destination stringByAppendingPathComponent:@"test.zip"] append:NO];
	NSLog(@"%d", result);
}

@end

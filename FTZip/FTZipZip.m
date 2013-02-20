//
//  Copyright (c) 2013 feedtailor Inc. All rights reserved.
//

#import "FTZipZip.h"
#import "minizip/zip.h"

#define BUF_SIZE	(1024 * 256)

/* Table of CRCs of all 8-bit messages. */
static unsigned long __crc_table[256];

/* Flag: has the table been computed? Initially false. */
static int __crc_table_computed = 0;

/* Make the table for a fast CRC. */
static void __make_crc_table(void)
{
	unsigned long c;
	int n, k;
	for (n = 0; n < 256; n++) {
		c = (unsigned long) n;
		for (k = 0; k < 8; k++) {
			if (c & 1) {
				c = 0xedb88320L ^ (c >> 1);
			} else {
				c = c >> 1;
			}
		}
		__crc_table[n] = c;
	}
	__crc_table_computed = 1;
}

/*
 Update a running crc with the bytes buf[0..len-1] and return
 the updated crc. The crc should be initialized to zero. Pre- and
 post-conditioning (one's complement) is performed within this
 function so it shouldn't be done by the caller. Usage example:
 
 unsigned long crc = 0L;
 
 while (read_buffer(buffer, length) != EOF) {
 crc = update_crc(crc, buffer, length);
 }
 if (crc != original_crc) error();
 */
static unsigned long __update_crc(unsigned long crc,
								   unsigned char *buf, int len)
{
	unsigned long c = crc ^ 0xffffffffL;
	int n;
	
	if (!__crc_table_computed)
		__make_crc_table();
	for (n = 0; n < len; n++) {
		c = __crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
	}
	return c ^ 0xffffffffL;
}

@interface FTZipZip ()

@property (nonatomic, retain) NSArray* srcPaths;
@property (nonatomic, retain) NSString* srcBasePath;
@property (nonatomic, retain) NSData* srcData;
@property (nonatomic, retain) NSString* dstFilename;

-(BOOL) writeFile:(NSString*)path;

@end

@implementation FTZipZip

@synthesize password, pathEncoding;
@synthesize srcPaths, srcBasePath, srcData, dstFilename;

-(id) initWithContentsOfFiles:(NSArray *)paths basePath:(NSString *)basePath
{
	self = [super init];
	if (self) {
		self.srcPaths = paths;
		self.srcBasePath = [basePath stringByStandardizingPath];
		self.pathEncoding = NSUTF8StringEncoding;
	}
	return self;
}

-(id) initWithData:(NSData*)data filename:(NSString*)filename
{
	self = [super init];
	if (self) {
		self.srcData = data;
		self.dstFilename = filename;
		self.pathEncoding = NSUTF8StringEncoding;
	}
	return self;
}

-(BOOL) writeToPath:(NSString*)path append:(BOOL)append
{
	if (!((self.srcData && self.dstFilename) || self.srcPaths)) {
		return NO;
	}
	
	zfile = zipOpen([path UTF8String], (append) ? 1 : 0);
	if (!zfile) {
		return NO;
	}
	
	if (self.srcData && self.dstFilename) {
		int crc = (self.password) ? __update_crc(0, (unsigned char*)[self.srcData bytes], [self.srcData length]) : 0; 
		zipOpenNewFileInZip3(zfile,	// file
							[self.dstFilename cStringUsingEncoding:self.pathEncoding],	// filename
							0,	// zipfi
							0,	// extrafield_local
							0,	// extrafield_local
							0,	// extrafield_global
							0,	// extrafield_global
							0,	// comment
							Z_DEFLATED,	// method
							Z_DEFAULT_COMPRESSION,	// level
							0,	// raw
							 -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, [self.password UTF8String], crc
							);
		
		zipWriteInFileInZip(zfile, [self.srcData bytes], [self.srcData length]);
		zipCloseFileInZip(zfile);
	} else if (self.srcPaths) {
		NSFileManager* mgr = [[NSFileManager alloc] init];
		
		for (NSString* path in self.srcPaths) {
			BOOL isDir = NO;
			if (![mgr fileExistsAtPath:path isDirectory:&isDir]) {
				continue;
			}
			if (isDir) {
				NSArray* subpaths = [mgr subpathsAtPath:path];
				for (NSString* subpath in subpaths) {
					[self writeFile:[path stringByAppendingPathComponent:subpath]];
				}
			} else {
				[self writeFile:path];
			}
		}
	}
	
	zipClose(zfile, 0);
	
	return YES;
}

#pragma mark -

-(BOOL) writeFile:(NSString*)path
{
	path = [path stringByStandardizingPath];
	NSString* filename = path;
	if (self.srcBasePath) {
		filename = [path stringByReplacingOccurrencesOfString:self.srcBasePath withString:@""];
	}
	
	static uint8_t buf[BUF_SIZE];

	int crc = 0;
	if (self.password) {
		NSInputStream* input = [NSInputStream inputStreamWithFileAtPath:path];
		[input open];
		while (1) {
			NSInteger read = [input read:buf maxLength:BUF_SIZE];
			if (read < 0) {
				break;
			}
			
			crc = __update_crc(crc, buf, read);
			
			if (read < BUF_SIZE) {
				break;
			}
		}
		[input close];
	}
	
	zipOpenNewFileInZip3(zfile,	// file
						 [filename cStringUsingEncoding:self.pathEncoding],	// filename
						 0,	// zipfi
						 0,	// extrafield_local
						 0,	// extrafield_local
						 0,	// extrafield_global
						 0,	// extrafield_global
						 0,	// comment
						 Z_DEFLATED,	// method
						 Z_DEFAULT_COMPRESSION,	// level
						 0,	// raw
						 -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, [self.password UTF8String], crc
						 );
	
	NSInputStream* input = [NSInputStream inputStreamWithFileAtPath:path];
	[input open];
	while (1) {
		NSInteger read = [input read:buf maxLength:BUF_SIZE];
		if (read < 0) {
			break;
		}

		zipWriteInFileInZip(zfile, buf, read);
		
		if (read < BUF_SIZE) {
			break;
		}
	}
	[input close];
	zipCloseFileInZip(zfile);

	return YES;
}

@end

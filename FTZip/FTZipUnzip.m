//
//  Copyright (c) 2013 feedtailor Inc. All rights reserved.
//


#import "FTZipUnzip.h"
#import "minizip/unzip.h"

NSString* FTZipUnzipErrorDomain = @"FTZipUnzipErrorDomain";

@interface FTZipUnzip ()

-(NSString*) pathWithBytes:(void*)bytes length:(size_t)length;

@end

@implementation FTZipUnzip

@synthesize password;
@synthesize pathEncoding;
@synthesize pathEncodingDetector;
@synthesize error;

-(id) initWithContentsOfFile:(NSString*)path
{
	if (self = [super init]) {
		_unzFile = unzOpen([path UTF8String]);
		if (!_unzFile) {
			self = nil;
			return nil;
		}
		
		pathEncoding = NSUTF8StringEncoding;
	}
	return self;
}

-(id) initWithData:(NSData*)data
{
	return nil;
}

-(void) dealloc
{
	if (_unzFile) {
		unzClose(_unzFile);
		_unzFile = nil;
	}
	self.password = nil;
	self.error = nil;
}

-(BOOL) writeToPath:(NSString*)path overWrite:(BOOL)overWrite
{
	return [self write:nil toPath:path overWrite:overWrite];
}

-(BOOL) write:(NSArray*)files toPath:(NSString*)path overWrite:(BOOL)overWrite
{
	self.error = nil;
	
	BOOL ret = YES;
	int zRet = unzGoToFirstFile(_unzFile);
	
	if (zRet != UNZ_OK) {
		NSLog(@"Fail to unzGoToFirstFile");
		return NO;
	}
	
	@autoreleasepool {
		NSFileManager* manager = [[NSFileManager alloc] init];
		
		const char* macosxPrefix = "__MACOSX/";
		
		char filename[1024];
		char buf[4096];
		do {
			if (password) {
				NSData* data = [password dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
				char* pw = malloc([data length] + 1);
				memset(pw, 0, [data length] + 1);
				[data getBytes:pw length:[data length]];
				zRet = unzOpenCurrentFilePassword(_unzFile, pw);
				free(pw);
			} else {
				zRet = unzOpenCurrentFilePassword(_unzFile, NULL);
			}
			if (zRet != UNZ_OK) {
				NSLog(@"Fail to unzOpenCurrentFile");
				ret = NO;
				break;
			}
			
			unz_file_info fileInfo = {0};
			zRet = unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, sizeof(filename), NULL, 0, NULL, 0);
			if (zRet != UNZ_OK) {
				NSLog(@"Fail to unzGetCurrentFileInfo");
				unzCloseCurrentFile(_unzFile);
				ret = NO;
				break;
			}
			if (strncmp(filename, macosxPrefix, sizeof(macosxPrefix)) == 0) {
				//			NSLog(@"__MACOSX is ignored");
				pathEncoding = NSUTF8StringEncoding;
				unzCloseCurrentFile(_unzFile);
				zRet = unzGoToNextFile(_unzFile);
				continue;
			}
			
			NSString* subPath = [self pathWithBytes:filename length:fileInfo.size_filename];
			if (!subPath) {
				unzCloseCurrentFile(_unzFile);
				zRet = unzGoToNextFile(_unzFile);
				continue;			
			}
			
			// 空ディレクトリ
			BOOL isEmptyDir = ([subPath hasSuffix:@"/"] || [subPath hasSuffix:@"\\"]);
			subPath = [subPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
			if (!(!files || [files containsObject:subPath])) {
				unzCloseCurrentFile(_unzFile);
				zRet = unzGoToNextFile(_unzFile);
				continue;
			}
			
			NSString* fullPath = [path stringByAppendingPathComponent:subPath];
			if (isEmptyDir) {
				ret = [manager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
			} else {
				ret = [manager createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
				if ([manager fileExistsAtPath:fullPath] && !overWrite) {
					//				NSLog(@"%@ is exists", fullPath);
					unzCloseCurrentFile(_unzFile);
					zRet = unzGoToNextFile(_unzFile);
					continue;
				}
				
				FILE* fp = fopen([fullPath UTF8String], "wb");
				if (fp) {
					int readSize;
					do {
						readSize = unzReadCurrentFile(_unzFile, buf, sizeof(buf));
						if (readSize < 0) {
							if (readSize == -3) {
								// bad data
								self.error = [NSError errorWithDomain:FTZipUnzipErrorDomain code:kFTZipUnzipDecryptionError userInfo:nil];
							}
							ret = NO;
							break;
						}
						if (readSize > 0) {
							int writeSize = fwrite(buf, 1, readSize, fp);
							if(writeSize != readSize) {
								ret = NO;
								break;
							}
						}
					} while (readSize > 0);
					
					if(readSize == 0) {
						fclose(fp);
					}
				} else {
					ret = NO;
				}
			}
			
			unzCloseCurrentFile(_unzFile);
			zRet = unzGoToNextFile(_unzFile);
		} while (zRet == UNZ_OK && zRet != UNZ_END_OF_LIST_OF_FILE && ret);
	}	
	
	return ret;
}

-(NSArray*) contentPaths
{
	int zRet = unzGoToFirstFile(_unzFile);
	
	if (zRet != UNZ_OK) {
		NSLog(@"Fail to unzGoToFirstFile");
		return nil;
	}

	NSMutableArray* paths = [NSMutableArray array];
	
	@autoreleasepool {
			
		const char* macosxPrefix = "__MACOSX/";
		
		char filename[1024];
		do {
			if (password) {
				NSData* data = [password dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
				char* pw = malloc([data length] + 1);
				memset(pw, 0, [data length] + 1);
				[data getBytes:pw length:[data length]];
				zRet = unzOpenCurrentFilePassword(_unzFile, pw);
				free(pw);
			} else {
				zRet = unzOpenCurrentFilePassword(_unzFile, NULL);
			}
			if (zRet != UNZ_OK) {
				NSLog(@"Fail to unzOpenCurrentFile");
				return nil;
			}
			
			unz_file_info fileInfo = {0};
			zRet = unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, sizeof(filename), NULL, 0, NULL, 0);
			if (zRet != UNZ_OK) {
				NSLog(@"Fail to unzGetCurrentFileInfo");
				unzCloseCurrentFile(_unzFile);
				return nil;
			}
			if (strncmp(filename, macosxPrefix, sizeof(macosxPrefix)) == 0) {
				//			NSLog(@"__MACOSX is ignored");
				pathEncoding = NSUTF8StringEncoding;
				unzCloseCurrentFile(_unzFile);
				zRet = unzGoToNextFile(_unzFile);
				continue;
			}
					
			NSString* subPath = [self pathWithBytes:filename length:fileInfo.size_filename];
			if (subPath) {
				subPath = [subPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
				[paths addObject:subPath];
			}
			
			unzCloseCurrentFile(_unzFile);
			zRet = unzGoToNextFile(_unzFile);
		} while (zRet == UNZ_OK && zRet != UNZ_END_OF_LIST_OF_FILE);
	}

	return paths;
}

#pragma mark -

-(NSString*) pathWithBytes:(void*)bytes length:(size_t)length
{
	NSString* path = [[NSString alloc] initWithBytes:bytes length:length encoding:pathEncoding];
	if (!path) {
		if (pathEncodingDetector && [pathEncodingDetector respondsToSelector:@selector(detectEncodingWithBytes:length:)]) {
			NSStringEncoding encoding = [pathEncodingDetector detectEncodingWithBytes:bytes length:length];
			path = [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];
			if (path) {
				self.pathEncoding = encoding;
			}
		}
	}
	return path;
}

@end

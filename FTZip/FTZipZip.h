//
//  Copyright (c) 2013 feedtailor Inc. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface FTZipZip : NSObject
{
	void* zfile;
}

/// パスワード
@property (nonatomic, copy) NSString* password;
/// ファイルパスの文字コード
@property (nonatomic, assign) NSStringEncoding pathEncoding;

-(id) initWithContentsOfFiles:(NSArray*)paths basePath:(NSString*)basePath;
-(id) initWithData:(NSData*)data filename:(NSString*)filename;

// 圧縮
-(BOOL) writeToPath:(NSString*)path append:(BOOL)append;

@end

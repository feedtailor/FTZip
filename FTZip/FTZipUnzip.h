//
//  Copyright (c) 2013 feedtailor Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* FTZipUnzipErrorDomain;
enum {
	kFTZipUnzipDecryptionError = -1, // あくまで確定では無く推定
};

@interface FTZipUnzip : NSObject {
	void*		_unzFile;
	
	NSString* password;
	// 本来なら自動判別すべき
	NSStringEncoding pathEncoding;
	// 自働判別用
	__weak id pathEncodingDetector;
	
	NSError* error;
}

/// パスワード
@property (nonatomic, copy) NSString* password;
/// ファイルパスの文字コード
@property (nonatomic, assign) NSStringEncoding pathEncoding;
/// ファイルパスの文字コード自動判別オブジェクト (FTZipUnzipPathEncodingDetect参照)
@property (nonatomic, weak) id pathEncodingDetector;
/// エラー
@property (nonatomic, retain) NSError* error;

-(id) initWithContentsOfFile:(NSString*)path;
-(id) initWithData:(NSData*)data;

// 全部解凍
-(BOOL) writeToPath:(NSString*)path overWrite:(BOOL)overWrite;
// 部分解凍: files=nilで全部解凍
-(BOOL) write:(NSArray*)files toPath:(NSString*)path overWrite:(BOOL)overWrite;

// 含まれているファイルの一覧
-(NSArray*) contentPaths;

@end

@interface NSObject (FTZipUnzipPathEncodingDetect)
// 自動判別用 : FTCharacterEncodingTool をそのまま使うとよい
-(NSStringEncoding) detectEncodingWithBytes:(void*)bytes length:(size_t)length;

@end

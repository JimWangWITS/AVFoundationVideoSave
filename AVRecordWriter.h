#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <Photos/Photos.h>

@interface AVRecordWriter : NSObject

@property (nonatomic, copy, readonly) NSString *videoPath;

+ (instancetype)recordingWriterWithVideoPath:(NSString*)videoPath
                             resolutionWidth:(NSInteger)width
                            resolutionHeight:(NSInteger)height
                                audioChannel:(int)channel
                                  sampleRate:(Float64)rate;

- (BOOL)writeWithSampleBuffer:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;

- (void)finishWritingWithCompletionHandler:(void (^)(void))completion;

@end
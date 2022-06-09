#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <Photos/Photos.h>

@interface AVCamManager : NSObject

@property (nonatomic, assign, readonly) BOOL isRecording;

@property (nonatomic, assign) CGFloat maxRecordingTime;
@property (nonatomic, assign, readonly) CGFloat currentRecordingTime;

@property (nonatomic, strong) NSString *videoPath;

@property (nonatomic, assign) BOOL autoSaveVideo;

@property (nonatomic, strong) AVCaptureMovieFileOutput *videoFileOutput;

- (instancetype)init:(AVCaptureDevicePosition)pos;
- (AVCaptureSession *)captureSession:(NSString *)preset;
- (NSUInteger)cameraCount;
- (CMTime)recordedDuration;
- (NSURL *)uniqueURL;
- (BOOL)isRecording;

- (void)startCapture;
- (void)stopCapture;
- (void)startRecordingCapMov;
- (void)stopRecordingCapMov;
- (void)startRecoring;
- (void)stopRecoring;
- (void)stopRecordingHandler;
- (void)saveCurrentRecordingVideo;


@end
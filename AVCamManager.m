#import "AVCamManager.h"
#import "AVRecordWriter.h"

@interface AVCamManager () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, CAAnimationDelegate, AVCaptureFileOutputRecordingDelegate>
{
    NSInteger _resolutionWidth;
    NSInteger _resolutionHeight;
    
    int _audioChannel;
    Float64 _sampleRate;
}

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDevice *camDevice;

@property (nonatomic, strong) AVCaptureDeviceInput *camInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

@property (nonatomic, strong) dispatch_queue_t captureQueue;

@property (nonatomic, strong) AVRecordWriter *recordWriter;

@property (nonatomic, assign) CMTime  startRecordingCMTime;
@property (nonatomic, assign) CGFloat currentRecordingTime;

@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, copy) NSString *cacheDirectoryPath;

@property (nonatomic, strong) NSURL *videoFileURL;
@property (nonatomic, strong) NSURL *outputURL;

@end

@implementation AVCamManager

- (void)startRecordingCapMov {
    if (![self isRecording]) {
        self.outputURL = [self uniqueURL];
        NSLog(@"url %@",self.outputURL);
        AVCaptureConnection *c = [self.videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (c.active) {
            NSLog(@"ACTIVE DEVICE");
            [self.videoFileOutput startRecordingToOutputFileURL:self.outputURL recordingDelegate:self];
        } else {
            NSLog(@"device is not active...");
            [self.videoFileOutput startRecordingToOutputFileURL:self.outputURL recordingDelegate:self];
        }
    }
}

- (CMTime)recordedDuration {
    return self.videoFileOutput.recordedDuration;
}

- (NSURL *)uniqueURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *directionPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"camera_movie"];

    NSLog(@"unique url ：%@",directionPath);
    if (![fileManager fileExistsAtPath:directionPath]) {
        [fileManager createDirectoryAtPath:directionPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *filePath = [directionPath stringByAppendingPathComponent:@"camera_movie.mov"];
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    return [NSURL fileURLWithPath:filePath];

    return nil;
}

- (void)stopRecordingCapMov {
    if ([self isRecording]) {
        [self.videoFileOutput stopRecording];
    }
}

- (NSUInteger)cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (void)dealloc
{
    // NSLog(@"dealloc");
    [_captureSession stopRunning];
    
    _camDevice = nil;
    _captureSession   = nil;
    _camInput = nil;
    _audioOutput      = nil;
    _videoOutput      = nil;
    _audioConnection  = nil;
    _videoConnection  = nil;
    _recordWriter  = nil;
    _captureQueue     = nil;
}

+ (void)load
{
    NSString *cacheDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                                stringByAppendingPathComponent:NSStringFromClass([self class])];
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (BOOL)isRecording {
    return self.videoFileOutput.isRecording;
}


- (NSString *)cacheDirectoryPath
{
    if (!_cacheDirectoryPath) {
        _cacheDirectoryPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                               stringByAppendingPathComponent:NSStringFromClass([self class])];
    }
    return _cacheDirectoryPath;
}

- (AVCaptureSession *)captureSession:(NSString *)preset
{
    [self.captureSession beginConfiguration];
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        
        _captureSession.sessionPreset = preset;
        if ([_captureSession canAddInput:self.camInput]) {
            [_captureSession addInput:self.camInput];
        }
        // if ([_captureSession canAddInput:self.audioInput]) {
        //     [_captureSession addInput:self.audioInput];
        // }
        // if ([_captureSession canAddOutput:self.videoOutput]) {
        //     [_captureSession addOutput:self.videoOutput];
        // }
        // if ([_captureSession canAddOutput:self.audioOutput]) {
        //     [_captureSession addOutput:self.audioOutput];
        // }
        if ([self.captureSession canAddOutput:self.videoFileOutput]) {
            [self.captureSession addOutput:self.videoFileOutput];
            NSLog(@"add movie output success");
        }
        _resolutionWidth  = 400;//1280;
        _resolutionHeight = 720;
        
        // self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    [self.captureSession commitConfiguration];
    return _captureSession;
}


- (AVCaptureDevice *) camDevice:(AVCaptureDevicePosition)position
{
    if (!_camDevice) {

        AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession =
        [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                        mediaType:AVMediaTypeVideo
                                        position:position];
        NSArray *captureDevices = [captureDeviceDiscoverySession devices];
        for (AVCaptureDevice *device in captureDevices){
            if (device.position == position){
                    _camDevice = device;
                    break;
            }
        }
    }
    // if we didnt get the desired device at position, lets go back to the default one
    if (!_camDevice) {
        NSLog(@"Failed to initialize the camera...You could use default one.");
        _camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    } else {
        NSLog(@"Get the device successfully!");
    }
    [_camDevice formats];
    return _camDevice;
}

- (AVCaptureDeviceInput *)camInput:(AVCaptureDevice *)device
{
    if (!_camInput) {
        NSError *error = nil;
        _camInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        if (error) {
            NSLog(@"Can not get the input of the Camera...");
        } else {
            NSLog(@"Get the input of the Cam!");
        }
    }
    return _camInput;
}

- (AVCaptureDeviceInput *)audioInput
{
    if (!_audioInput) {
        AVCaptureDevice *captureDeviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error = nil;
        _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDeviceAudio error:&error];
        if (error) {
            NSLog(@"Failed to initialize the mic...");
        }
    }
    return _audioInput;
}

- (AVCaptureVideoDataOutput *)videoOutput
{
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        _videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), kCVPixelBufferPixelFormatTypeKey, nil];
    }
    return _videoOutput;
}

- (AVCaptureAudioDataOutput *)audioOutput
{
    if (!_audioOutput) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

- (dispatch_queue_t)captureQueue 
{
    if (!_captureQueue) {
        _captureQueue = dispatch_queue_create("com.wits.AVRecorder", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

- (AVCaptureConnection *)videoConnection
{
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    return _videoConnection;
}

- (AVCaptureConnection *)audioConnection
{
    if (!_audioConnection) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

- (instancetype)init:(AVCaptureDevicePosition)pos
{
    if (self = [super init]) {
        _maxRecordingTime = 10.0;
        _autoSaveVideo = NO;
    }
    [self captureQueue];
    [AVCamManager load];
    [self cacheDirectoryPath];
    AVCaptureDevice *device = [self camDevice:pos];
    [self camInput:device];
    // [self videoOutput];
    [self videoFileOutput];
    self.videoFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    // [self videoConnection];
    // [self audioConnection];
    return self;
}

- (void)startCapture
{
    _isRecording = NO;
    _startRecordingCMTime = CMTimeMake(0, 0);
    _currentRecordingTime = 0;
    if (![self.captureSession isRunning]) {
        dispatch_async([self captureQueue], ^{
            [self.captureSession startRunning];
        });
    }
}

- (void)stopCapture
{
    if ([self.captureSession isRunning]) {
        dispatch_async([self captureQueue], ^{
            [self.captureSession stopRunning];
        });
    }
}

- (void)startRecoring
{
    if (self.isRecording) {
        return;
    }
    _isRecording = YES;
}

- (void)stopRecoring
{
    [self stopRecordingHandler];
}

- (void)stopRecordingHandler
{
    if (!_isRecording) {
        return;
    }
    _isRecording = NO;
    _videoFileURL = [NSURL fileURLWithPath:_recordWriter.videoPath];
    NSLog(@"TEST!stepRecordingHandler");
    dispatch_async(self.captureQueue, ^{
        __weak typeof(self) weakSelf = self;
        [_recordWriter finishWritingWithCompletionHandler:^{
            weakSelf.isRecording = NO;
            weakSelf.startRecordingCMTime = CMTimeMake(0, 0);
            weakSelf.currentRecordingTime = 0;
            weakSelf.recordWriter = nil;
            
            if (weakSelf.autoSaveVideo) {
                NSLog(@"Saving Video...");
                [self saveCurrentRecordingVideo];
            }
        }];
    });
}


- (void)saveCurrentRecordingVideo
{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            [self saveCurrentRecordingVideoToPhotoLibrary];
        }];
    } else {
        [self saveCurrentRecordingVideoToPhotoLibrary];
    }
}

- (void)saveCurrentRecordingVideoToPhotoLibrary
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:_videoFileURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Save video success!");
        } else {
            NSLog(@"Save video failure!");
        }
    }];
}

// - (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
// {
//     if (!_isRecording) {
//         return;
//     }
    
//     BOOL isVideo = YES;
//     if (captureOutput != self.videoOutput) {
//         isVideo = NO;
//         NSLog(@"NOOOOO");
//     }

//     if (!_recordWriter && !isVideo) {
//         CMFormatDescriptionRef formatDescriptionRef = CMSampleBufferGetFormatDescription(sampleBuffer);
        
//         const AudioStreamBasicDescription *audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescriptionRef);
//         _sampleRate = audioStreamBasicDescription -> mSampleRate;
//         _audioChannel = audioStreamBasicDescription -> mChannelsPerFrame;
        
//         NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//         dateFormatter.dateFormat = @"HH:mm:ss";
//         NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:[[NSDate date] timeIntervalSince1970]];
//         NSString *currentDateString = [dateFormatter stringFromDate:currentDate];
//         NSString *videoName = [NSString stringWithFormat:@"video_%@.mp4", currentDateString];
//         _videoPath = [self.cacheDirectoryPath stringByAppendingPathComponent:videoName];
        
//         _recordWriter = [AVRecordWriter recordingWriterWithVideoPath:_videoPath
//                                                               resolutionWidth:_resolutionWidth resolutionHeight:_resolutionHeight
//                                                                  audioChannel:_audioChannel sampleRate:_sampleRate];
//     }
    
//     CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//     if (_startRecordingCMTime.value == 0) {
//         _startRecordingCMTime = presentationTimeStamp;
//     }
    
//     CMTime subtract = CMTimeSubtract(presentationTimeStamp, _startRecordingCMTime);
//     _currentRecordingTime = CMTimeGetSeconds(subtract);
//     if (_currentRecordingTime > _maxRecordingTime) {
//         if (_currentRecordingTime - _maxRecordingTime >= 0.1) {
//             return;
//         }
//     }
//     [_recordWriter writeWithSampleBuffer:sampleBuffer isVideo:isVideo];
// }
- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error
{
    NSLog(@"capture output");
    if (error) {
        NSLog(@"record error :%@",error);
    } else {

    }
    self.outputURL = nil;
}
@end
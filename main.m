#import "AVCamManager.h"
#import "AVRecordWriter.h"

int main(int argc, char * argv[])
{
    // Record 5 seconds for test
    NSInteger time = 5;
    // The number of device(defualt cam)
    AVCaptureDevicePosition pos = 0;
    // Set 1280x720 to meet the resolution of display
    NSString *preset = AVCaptureSessionPreset1280x720;

    AVCamManager *camManager = [[AVCamManager alloc] init:pos];
    AVCaptureSession* sess = [camManager captureSession:preset];
    sess.sessionPreset = preset;
    
    [sess startRunning];
    [camManager startCapture];
    [camManager startRecordingCapMov];

    [NSThread sleepForTimeInterval:time];

    [camManager stopRecordingCapMov];
    [camManager stopCapture];
    return 0;
}

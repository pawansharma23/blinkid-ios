//
//  ViewController.m
//  BlinkID-sample
//
//  Created by Jura on 03/04/15.
//  Copyright (c) 2015 MicroBlink. All rights reserved.
//

#import "ViewController.h"

#import <MicroBlink/MicroBlink.h>

#import "PPScannedViewController.h"

@interface ViewController () <PPScanDelegate, PPScannedViewControllerDelegate>

@property (nonatomic, strong) UIViewController<PPScanningViewController>* cameraViewController;

@property (nonatomic, strong) PPUsdlRecognizerResult *usdlRecognizerResult;

@property (nonatomic, strong) PPImageMetadata *imageMetadata;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Method allocates and initializes the Scanning coordinator object.
 * Coordinator is initialized with settings for scanning
 *
 *  @param error Error object, if scanning isn't supported
 *
 *  @return initialized coordinator
 */
- (PPCoordinator *)coordinatorWithError:(NSError**)error {

    /** 0. Check if scanning is supported */

    if ([PPCoordinator isScanningUnsupportedForCameraType:PPCameraTypeBack error:error]) {
        return nil;
    }


    /** 1. Initialize the Scanning settings */

    // Initialize the scanner settings object. This initialize settings with all default values.
    PPSettings *settings = [[PPSettings alloc] init];

    // tell which metadata you want to receive. Metadata collection takes CPU time - so use it only if necessary!
    settings.metadataSettings.dewarpedImage = YES; // get dewarped image of ID documents


    /** 2. Setup the license key */

    // Visit www.microblink.com to get the license key for your app
    settings.licenseSettings.licenseKey = @"G5R3PKW5-7KUCFX6B-HHG4VJE4-76CSSGVD-6FJ6JFSP-5U4AH3JY-APWTQA7N-HABZVSIJ"; // Valid temporarily


    /** 3. Set up what is being scanned. See detailed guides for specific use cases. */


    // Document Detector

    PPDocumentDetectorSettings *documentDetectorSettings = [[PPDocumentDetectorSettings alloc] initWithNumStableDetectionsThreshold:1];

    PPDocumentSpecification *specification = [PPDocumentSpecification newFromPreset:PPDocumentPresetId1Card];

    PPDocumentDecodingInfo *documentInfo = [[PPDocumentDecodingInfo alloc] init];
    [documentInfo addEntry:[[PPDocumentDecodingInfoEntry alloc] initWithLocation:CGRectMake(0.0, 0.0, 1.0, 1.0) dewarpedHeight:700 uniqueId:@"IDCard1"]];
    [specification setDecodingInfo:documentInfo];

    [documentDetectorSettings setDocumentSpecifications:@[specification]];


    // MRTD detector

    PPDocumentDecodingInfo *mrtdInfo = [[PPDocumentDecodingInfo alloc] init];
    [mrtdInfo addEntry:[[PPDocumentDecodingInfoEntry alloc] initWithLocation:CGRectMake(0.0, 0.0, 1.0, 1.0) dewarpedHeight:700 uniqueId:@"MRTD"]];

    PPMrtdDetectorSettings *mrtdDetectorSettings = [[PPMrtdDetectorSettings alloc] initWithDocumentDecodingInfo:mrtdInfo];


    // MULTI detector

    PPMultiDetectorSettings *multiDetectorSettings = [[PPMultiDetectorSettings alloc] initWithSettingsArray:@[documentDetectorSettings, mrtdDetectorSettings]];
    multiDetectorSettings.allowMultipleResults = YES;


    // Detector recognizer

    PPDetectorRecognizerSettings *detectorRecognizerSettings = [[PPDetectorRecognizerSettings alloc] initWithDetectorSettings:multiDetectorSettings];
    [settings.scanSettings addRecognizerSettings:detectorRecognizerSettings];

    /** 4. Initialize the Scanning Coordinator object */

    PPCoordinator *coordinator = [[PPCoordinator alloc] initWithSettings:settings];

    return coordinator;
}

- (IBAction)didTapScan:(id)sender {

    /** Instantiate the scanning coordinator */
    NSError *error;
    PPCoordinator *coordinator = [self coordinatorWithError:&error];

    /** If scanning isn't supported, present an error */
    if (coordinator == nil) {
        NSString *messageString = [error localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Warning"
                                    message:messageString
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil, nil] show];

        return;
    }

    /** Allocate and present the scanning view controller */
    self.cameraViewController = [coordinator cameraViewControllerWithDelegate:self];

    // allow rotation if VC is displayed as a modal view controller
    self.cameraViewController.autorotate = YES;
    self.cameraViewController.supportedOrientations = UIInterfaceOrientationMaskAll;

    /** You can use other presentation methods as well */
    [self addChildViewController:self.cameraViewController];
    self.cameraViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.cameraViewController.view];
    [self.cameraViewController didMoveToParentViewController:self];
}

#pragma mark - PPScanDelegate

- (void)scanningViewControllerUnauthorizedCamera:(UIViewController<PPScanningViewController> *)scanningViewController {
    // Add any logic which handles UI when app user doesn't allow usage of the phone's camera
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController
                  didFindError:(NSError *)error {
    // Can be ignored. See description of the method
}

- (void)scanningViewControllerDidClose:(UIViewController<PPScanningViewController> *)scanningViewController {

    [scanningViewController willMoveToParentViewController:nil];
    [scanningViewController.view removeFromSuperview];
    [scanningViewController removeFromParentViewController];
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController didOutputMetadata:(PPMetadata *)metadata {

    // Check if metadata obtained is image
    if ([metadata isKindOfClass:[PPImageMetadata class]]) {
        PPImageMetadata *imageMetadata = (PPImageMetadata *)metadata;
        self.imageMetadata = imageMetadata;
    }
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController
              didOutputResults:(NSArray *)results {

    // Here you process scanning results. Scanning results are given in the array of PPRecognizerResult objects.

    // Collect data from the result
    for (PPRecognizerResult* result in results) {

        if ([result isKindOfClass:[PPDetectorRecognizerResult class]]) {
            PPDetectorRecognizerResult *detectorRecognizerResult = (PPDetectorRecognizerResult *)result;

            [self showDetectorResult:detectorRecognizerResult scanningViewController:scanningViewController];

            return;
        }
    };
}

// dismiss the scanning view controller when user presses OK.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showDetectorResult:(PPDetectorRecognizerResult *)result
    scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController {

    // pause scanning to avoid obtaining new detector results
    [scanningViewController pauseScanning];

    PPScannedViewController *scannedVc = [PPScannedViewController viewControllerFromStoryboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    scannedVc.imageMetadata = self.imageMetadata;
    scannedVc.delegate = self;

    [self addChildViewController:scannedVc];
    scannedVc.view.frame = self.view.bounds;
    [self.view addSubview:scannedVc.view];
    [scannedVc didMoveToParentViewController:self];
}

#pragma mark - PPScannedViewControlerDelegate

- (void)scannedViewControllerWillClose:(PPScannedViewController *)scannedViewController {
    [UIView animateWithDuration:0.4f
                     animations:^{
                         scannedViewController.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         [scannedViewController willMoveToParentViewController:nil];
                         [scannedViewController.view removeFromSuperview];
                         [scannedViewController removeFromParentViewController];

                         [self.cameraViewController resumeScanningAndResetState:YES];
                     }];
}

@end

//
//  NoCameraTests.m
//  NoCameraTests
//
//  Created by Dino on 09/02/16.
//  Copyright © 2016 MicroBlink. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MicroBlink/MicroBlink.h>

@interface NoCameraTests : XCTestCase <PPScanDelegate>
{
    NSMutableArray<XCTestExpectation*> *currentExpectations;
    int currentExpectationIndex;
}
@end

@implementation NoCameraTests

- (PPCoordinator *)coordinatorWithError:(NSError**)error {
    /** 1. Initialize the Scanning settings */

    // Initialize the scanner settings object. This initialize settings with all default values.
    PPSettings *settings = [[PPSettings alloc] init];


    /** 2. Setup the license key */

    // Visit www.microblink.com to get the license key for your app
    settings.licenseSettings.licenseKey = @"2DEESYGD-FBARAIM3-TQTY7MDM-AVYGMVF7-VFSVVJVA-X6UWKWVG-UC72SZK2-VZMF4ARL";

    /** 4. Initialize the Scanning Coordinator object */

//    settings.metadataSettings.debugMetadata.debugOcrInputFrame = YES;
//    settings.metadataSettings.successfulFrame = YES;
    settings.metadataSettings.debugMetadata.debugDetectionFrame = YES;
    PPCoordinator *coordinator = [[PPCoordinator alloc] initWithSettings:settings];
    
    return coordinator;
}

- (void)setUp {
  [super setUp];
    currentExpectationIndex = 0;
    currentExpectations = [NSMutableArray array];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

- (void)testMrtd {
    PPCoordinator *coordinator = [self coordinatorWithError:nil];
    [coordinator.currentSettings.scanSettings addRecognizerSettings:[[PPMrtdRecognizerSettings alloc] init]];
    [coordinator applySettings];

    NSArray *array = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:@"jpg" inDirectory:@"Images/MRTD"];
    for (int i = 0; i < array.count; i++) {
        [currentExpectations addObject:[self expectationWithDescription:[@"MRTD" stringByAppendingString:[NSString stringWithFormat:@"%d",i]]]];
    }
    for (NSString *path in array) {
        UIImage *mrtdImg = [[UIImage alloc] initWithContentsOfFile:path];
        [coordinator processImage:mrtdImg scanningRegion:CGRectMake(0.0, 0.0, 1.0, 1.0) delegate:self];
    }
    [self waitForExpectationsWithTimeout:currentExpectations.count*1.0 handler:nil];
}

- (void)testUkdl {
    PPCoordinator *coordinator = [self coordinatorWithError:nil];
    [coordinator.currentSettings.scanSettings addRecognizerSettings:[[PPUkdlRecognizerSettings alloc] init]];
    [coordinator applySettings];

    NSArray *array = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:@"jpg" inDirectory:@"Images/UKDL"];
    for (int i = 0; i < array.count; i++) {
        [currentExpectations addObject:[self expectationWithDescription:[@"UKDL" stringByAppendingString:[NSString stringWithFormat:@"%d",i]]]];
    }
    for (NSString *path in array) {
        UIImage *ukdlImg = [[UIImage alloc] initWithContentsOfFile:path];
        [coordinator processImage:ukdlImg scanningRegion:CGRectMake(0.0, 0.0, 1.0, 1.0) delegate:self];
    }
    [self waitForExpectationsWithTimeout:currentExpectations.count*1.0 handler:nil];
}

- (void)testUsdl {
    PPCoordinator *coordinator = [self coordinatorWithError:nil];
    [coordinator.currentSettings.scanSettings addRecognizerSettings:[[PPUsdlRecognizerSettings alloc] init]];
    [coordinator applySettings];

    NSArray *array = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:@"jpg" inDirectory:@"Images/USDL"];
    for (int i = 0; i < array.count; i++) {
        [currentExpectations addObject:[self expectationWithDescription:[@"USDL" stringByAppendingString:[NSString stringWithFormat:@"%d",i]]]];
    }
    for (NSString *path in array) {
        UIImage *usdlImg = [[UIImage alloc] initWithContentsOfFile:path];
        [coordinator processImage:usdlImg scanningRegion:CGRectMake(0.0, 0.0, 1.0, 1.0) delegate:self];
    }
    [self waitForExpectationsWithTimeout:currentExpectations.count*1.0 handler:nil];
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController didFindError:(NSError *)error {
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController didOutputResults:(NSArray *)results {
    if (results.count == 0 || results == nil) {
        return;
    }
    for (PPRecognizerResult *result in results) {
        [[currentExpectations objectAtIndex:currentExpectationIndex] fulfill];
    }
    currentExpectationIndex++;
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController didOutputMetadata:(PPMetadata *)metadata {
}

- (void)scanningViewControllerUnauthorizedCamera:(UIViewController<PPScanningViewController> *)scanningViewController {

}

- (void)scanningViewControllerDidClose:(UIViewController<PPScanningViewController> *)scanningViewController {
}

@end

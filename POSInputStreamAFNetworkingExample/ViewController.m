//
//  ViewController.m
//  POSInputStreamAFNetworkingExample
//
//  Created by Luka Zakrajsek on 30/09/15.
//  Copyright © 2015 Koofr. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <POSInputStreamLibrary/NSInputStream+POS.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.statusLabel.text = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)upload:(id)sender {
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];

    __block ALAsset *firstAsset = nil;
    __block ALAsset *lastAsset = nil;

    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if (group) {
                                   [group setAssetsFilter:[ALAssetsFilter allAssets]];
                                   [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stopAssets) {
                                       if (result) {
                                           if (firstAsset == nil) {
                                               firstAsset = result;
                                           }
                                           lastAsset = result;
                                       }
                                   }];
                               } else {
                                   if (lastAsset) {
                                       [self uploadAsset:firstAsset andAnother:lastAsset toUrl:@"https://httpbin.org/post" progressBlock:^(long long bytesWriten, long long bytesTotal) {
                                           self.statusLabel.text = [NSString stringWithFormat:@"%lld/%lld", bytesWriten, bytesTotal];
                                       } success:^(id responseObject) {
                                           // NSLog(@"Response: %@", responseObject);
                                           self.statusLabel.text = @"Uploaded";
                                       } failure:^(NSError *error) {
                                           self.statusLabel.text = @"Error";
                                       }];
                                   }
                               }
                           } failureBlock:^(NSError *error) {

                           }];
}

- (void) formData:(id<AFMultipartFormData>)formData appendAsset:(ALAsset*)asset fieldName:(NSString*)fieldName
{
    ALAssetRepresentation *assetRepresentation = asset.defaultRepresentation;
    NSString* assetFilename = assetRepresentation.filename;
    NSURL *assetUrl = assetRepresentation.url;
    unsigned long long assetSize = assetRepresentation.size;
    NSInputStream *assetInputStream = [NSInputStream pos_inputStreamForAFNetworkingWithAssetURL:assetUrl];

    [formData appendPartWithInputStream:assetInputStream name:fieldName fileName:assetFilename length:assetSize mimeType:@"image/jpeg"];
}

- (void) uploadAsset:(ALAsset*)asset andAnother:(ALAsset*)anotherAsset toUrl:(NSString*)url progressBlock:(void (^)(long long bytesWriten, long long bytesTotal))progressBlock success:(void (^)(id responseObject))success failure:(void (^)(NSError* error))failure
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    AFHTTPRequestOperation *op = [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [self formData:formData appendAsset:asset fieldName:@"file1"];
        [self formData:formData appendAsset:anotherAsset fieldName:@"file2"];
    } success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        failure(error);
    }];

    [op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        progressBlock(totalBytesWritten, totalBytesExpectedToWrite);
    }];
}

@end

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

    __block ALAsset *lastAsset = nil;

    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if (group) {
                                   [group setAssetsFilter:[ALAssetsFilter allAssets]];
                                   [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stopAssets) {
                                       if (result) {
                                           lastAsset = result;
                                       }
                                   }];
                               } else {
                                   if (lastAsset) {
                                       [self uploadAsset:lastAsset toUrl:@"https://httpbin.org/post" progressBlock:^(long long bytesWriten, long long bytesTotal) {
                                           self.statusLabel.text = [NSString stringWithFormat:@"%lld/%lld", bytesWriten, bytesTotal];
                                       } success:^(id responseObject) {
                                           self.statusLabel.text = @"Uploaded";
                                       } failure:^(NSError *error) {
                                           self.statusLabel.text = @"Error";
                                       }];
                                   }
                               }
                           } failureBlock:^(NSError *error) {

                           }];
}

- (void) uploadAsset:(ALAsset*)asset toUrl:(NSString*)url progressBlock:(void (^)(long long bytesWriten, long long bytesTotal))progressBlock success:(void (^)(id responseObject))success failure:(void (^)(NSError* error))failure
{
    ALAssetRepresentation *assetRepresentation = asset.defaultRepresentation;
    NSString* assetFilename = assetRepresentation.filename;
    NSURL *assetUrl = assetRepresentation.url;
    unsigned long long assetSize = assetRepresentation.size;
    NSInputStream *assetInputStream = [NSInputStream pos_inputStreamForAFNetworkingWithAssetURL:assetUrl];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    AFHTTPRequestOperation *op = [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithInputStream:assetInputStream name:@"file" fileName:assetFilename length:assetSize mimeType:@"image/jpeg"];
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

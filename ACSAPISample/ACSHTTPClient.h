//
//  ACSHTTPClient.h
//  ACSAPISample
//
//  Created by Steve Wilson on 4/28/15.
//  Copyright (c) 2015 Steve Wilson. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import "AFNetworkActivityIndicatorManager.h"

@interface ACSHTTPClient : AFHTTPRequestOperationManager
+ (instancetype)sharedClient;

//POSTs
- (void)readBarcode: (NSDictionary*)parameters
       completion: (void (^)(NSInteger, NSMutableArray *, NSError *))callback;

@end

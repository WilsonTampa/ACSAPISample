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
- (void)startOCR: (NSDictionary*)parameters
       completion: (void (^)(NSString *, NSError *))callback;

- (void)uploadWorkFile: (NSDictionary*)parameters
         completion: (void (^)(NSData *, NSError *))callback;

-(void)getOCRResults:(NSString*)processId
          completion: (void (^)(NSString *, NSString *, NSError *))callback;
@end

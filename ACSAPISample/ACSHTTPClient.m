//
//  ACSHTTPClient.m
//  ACSAPISample
//
//  Created by Steve Wilson on 4/28/15.
//  Copyright (c) 2015 Steve Wilson. All rights reserved.
//

#import "ACSHTTPClient.h"
#import "Barcode.h"

@implementation ACSHTTPClient
static ACSHTTPClient* __sharedClient = nil;

+ (instancetype)sharedClient
{
    if (!__sharedClient) {
        NSString *serverString = @"https://api.accusoft.com";
        NSAssert([serverString length] > 0, @"ACS Server url is invalid: %@", serverString);
        __sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:serverString]];
    };
    
    return __sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWiFi:
            case AFNetworkReachabilityStatusReachableViaWWAN:
                // Our connection is fine
                // Resume our requests or do nothing
                [__sharedClient.operationQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
            {
                //not reachable
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection error"
                                                                message:@"Please check your Internet connection and try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                
                [alert show];
                //[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
                
                [__sharedClient.operationQueue setSuspended:YES];
            }
                break;
        }
    }];
    [self.reachabilityManager startMonitoring];
    
    
    if (self) {
        //initialization
        self.operationQueue.maxConcurrentOperationCount = 15;
        
        //set request response serializer
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
        
       // [requestSerializer setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
        [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [requestSerializer setValue:@"K20745910126200821453" forHTTPHeaderField:@"acs-api-key"];
        
        self.requestSerializer = requestSerializer;
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        [self addNetworkObserver];
        
    }
    return self;
}

- (void)addNetworkObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(HTTPOperationDidFinish:)
                                                 name:AFNetworkingOperationDidFinishNotification
                                               object:nil];
}

- (void)HTTPOperationDidFinish:(NSNotification *)notification
{
    AFHTTPRequestOperation *operation = (AFHTTPRequestOperation *)[notification object];
    if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
        return;
    }
    if (operation.error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection error"
                                                        message:@"Please check your Internet connection and try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        //[alert show];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
}

// API Security
- (void)setAuthorizationCodeWithUserName:(NSString *)userName andPassword:(NSString *)password
{
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:userName password:password];
}

- (void)readBarcode:(NSDictionary *)parameters completion:(void (^)(NSInteger, NSMutableArray *, NSError *))callback
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    //can add types and region later
    NSString *theBarcodePost = [NSString stringWithFormat:@"/v1/barcodeReaders"];
     NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"barcode.jpg"], 1.0);
    [self POST:theBarcodePost
    parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"barcodeImage" fileName:@"barcode.jpg" mimeType:@"image/jpeg"];
    }
       success:^(AFHTTPRequestOperation *operation, id responseObject){
                //build a barcode object with the results
                Barcode *theReturnedBarcode = [[Barcode alloc]init];
                theReturnedBarcode.type = [[responseObject objectForKey:@"results"]objectForKey:@"type"];
                theReturnedBarcode.value = [[responseObject objectForKey:@"results"]objectForKey:@"value"];
                if (callback)
                {
                    callback([responseObject statusCode], results, nil);
                }
            
        }failure:^(AFHTTPRequestOperation *operation, NSError *error){
            
     }];
}



@end

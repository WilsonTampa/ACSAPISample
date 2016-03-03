//
//  ACSHTTPClient.m
//  ACSAPISample
//
//  Created by Steve Wilson on 4/28/15.
//  Copyright (c) 2015 Steve Wilson. All rights reserved.
//

#import "ACSHTTPClient.h"
#import "Barcode.h"

// This uniquely identifies the background session used to upload files in the background.
NSString *const kSessionID = @"com.accusoft.PrizmShare.BackgroundUploadSession";

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
        
        [requestSerializer setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
        [requestSerializer setValue:@"wPR3lzfpZnoaRIv7uyuS9l4Fy1L6EltUkyhy-OL7q6xHWJRnoFZMEIyNr5_Pxmv6" forHTTPHeaderField:@"acs-api-key"];
        
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

- (void)startOCR:(NSDictionary *)parameters completion:(void (^)(NSString *, NSError *))callback
{
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableArray *results = [[NSMutableArray alloc] init];
    //can add types and region later
    NSString *theOCRPost = [NSString stringWithFormat:@"/v1/documentTextReaders"];
    [self POST:theOCRPost
    parameters:parameters
       success:^(AFHTTPRequestOperation *operation, id responseObject){
           NSLog(@"Got here");
           if (callback)
           {
               NSMutableArray *results = [[NSMutableArray alloc] init];
               //[results addObject:responseData];
               callback([responseObject objectForKey:@"processId"], nil);
           }
  //         [self getOCRResults:[responseObject objectForKey:@"processId"] completion:^(NSInteger statusCode,  NSMutableArray *theEventBack, NSError *error)
  //         {
           
  //             if (statusCode == 200) {
      
                   
    //           }
   //        }];
            
        }failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Error on startOCR");
            
     }];
}

- (void)getOCRResults:(NSString *)processId completion:(void (^)(NSString *, NSString *, NSError *))callback
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    //can add types and region later
    NSString *theOCRGet = [NSString stringWithFormat:@"/v1/documentTextReaders/%@", processId];
    [self GET:theOCRGet parameters:nil
      success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
           if (callback)
           {
               callback([responseObject objectForKey:@"state"], [responseObject objectForKey:@"output"], nil);
               //crashing here, figure out what to do with the callback
              // callback([responseObject statusCode], results, nil);
           }
           
       }failure:^(AFHTTPRequestOperation *operation, NSError *error){
           
       }];
}


- (void)uploadWorkFile:(NSDictionary *)parameters completion:(void (^)(NSData *, NSError *))callback
{
    // 1
    NSURL *url = [NSURL URLWithString:@"https://api.accusoft.com/PCCIS/V1/WorkFile"];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"tester.jpg"], 1.0);
    
    // 2
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setValue:@"wPR3lzfpZnoaRIv7uyuS9l4Fy1L6EltUkyhy-OL7q6xHWJRnoFZMEIyNr5_Pxmv6" forHTTPHeaderField:@"acs-api-key"];
    [request setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    
    // 3
    NSError *error = nil;    
    if (!error) {
        // 4
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                       fromData:imageData completionHandler:^(NSData *data,NSURLResponse *response,NSError *error)
                                        {
                                            if (error) {
                                                NSLog(@"got error");
                                                UIAlertView *alert =
                                                [[UIAlertView alloc] initWithTitle:@"Unable to Upload Image to OCR Service"
                                                                           message:@"Please check your Internet connection and try again."
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
                                                [alert show];

                                            } else {
                                                if (callback)
                                                {
                                                    NSMutableArray *results = [[NSMutableArray alloc] init];
                                                    //[results addObject:responseData];
                                                    callback(data, nil);
                                                }
                                               
                                               
                                                
                                            }
                                           NSLog(@"Got response");
                                       }];
        
        // 5
        [uploadTask resume];
    }
    
    
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSLog(@"FINISHED");
}






@end

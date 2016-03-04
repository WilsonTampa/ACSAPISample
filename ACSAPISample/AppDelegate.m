//
//  AppDelegate.m
//  ACSAPISample
//
//  Created by Steve Wilson on 4/28/15.
//  Copyright (c) 2015 Steve Wilson. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworkActivityLogger.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    /************Step 1 - Upload an Image to create a workFile for the service to work on**********************/
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: nil];
    [[ACSHTTPClient sharedClient]
     uploadWorkFile:parameters
     completion:^(NSData *theResults, NSError *error) {
         NSLog(@"Got back");
         //  call with workFileId
         NSError *jsonError;
         id responseData = [NSJSONSerialization
                            JSONObjectWithData:theResults
                            options:kNilOptions
                            error:&jsonError];
         NSDictionary *parameters = @{@"input":
                                          @{@"src":
                                                @{@"fileId": [responseData objectForKey:@"fileId"]},
                                            @"dest":
                                                @{@"format": @"text"}}};
         /******************Step 2 - Start the OCR process on the workFile we created******************/
         [[ACSHTTPClient sharedClient] startOCR:parameters
                                     completion:^(NSString *processId, NSError *error)
                                    {
                                         NSLog(@"SUCCESS");
         /******************Step 3 - Get the OCR results for the ProcessId we started******************/
       //  [[ACSHTTPClient sharedClient] getOCRResults:processId
       //                              completion:^(NSString *theState, NSString *theOCRResults, NSError *error)
       //                             {
       //                                 int retries = 0;
      //                                  //check to see if state="complete". If not, we need to keep checking
      //                                  NSLog(@"RESULTS: %@",theOCRResults);
      //                              }];
                                        [self retryGetOCRResults:processId :0];
                                        
                                }];

       //  else
       //  {
       //      UIAlertView *alert =
       //      [[UIAlertView alloc] initWithTitle:@"Unable to Read Barcode"
       //                                 message:@"Please check your Internet connection and try again."
         //                              delegate:nil
           //                   cancelButtonTitle:@"OK"
             //                 otherButtonTitles:nil];
           //  [alert show];
        // }
     }];

    return YES;
}

-(void)retryGetOCRResults:(NSString *)processId :(int)numRetries
{
    __block NSString *ocrStatus = @"start";
    __block int theNumRetries = numRetries;
    
        [[ACSHTTPClient sharedClient] getOCRResults:processId
                                     completion:^(NSString *theState, NSString *theOCRResults, NSError *error)
         {
             //check to see if state="complete". If not, we need to keep checking
             ocrStatus = theState;
             if (![ocrStatus isEqualToString:@"complete"] && theNumRetries <= 12)
             {
                 NSLog(@"Trying again!!!!!!!!!!!!!!!!!!");
                 theNumRetries++;
                 [self retryGetOCRResults:processId :theNumRetries];
                 
             }
             
             NSLog(@"STATUS %@ ----- RESULTS: %@",ocrStatus, theOCRResults);
         }];
   
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

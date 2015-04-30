//
//  Barcode.h
//  ACSAPISample
//
//  Created by Steve Wilson on 4/28/15.
//  Copyright (c) 2015 Steve Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Barcode : NSObject
@property (nonatomic, strong) NSString * value;
@property (nonatomic, strong) NSString * binaryValue;
@property (nonatomic, strong) NSString * confidence;
@property (nonatomic, strong) NSString * type;

@end

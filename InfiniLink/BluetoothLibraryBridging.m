//
//  BluetoothLibraryBridging.m
//  InfiniLink
//
//  Created by Xavi on 2023/6/9.
//

#import <Foundation/Foundation.h>
#import <BluetoothLibrary/BluetoothLibrary.h>

@interface TestClass : NSObject

@end

@implementation TestClass

CEProduct *product = nil;
+ (CEProduct *)Initialize
{
    if (product == nil)
        product = [CEProductK6 shareInstance];
    return product;
}


@end

//
//  XPDeviceStat.m
//  Xposed
//
//  Created by Brian Tamsing on 10/31/21.
//

#import "XPDeviceStat.h"

@implementation XPDeviceStat

- (instancetype)init {
    if (self = [super init]) {
        _id = [[NSUUID alloc] init];
        _names = [[NSMutableArray alloc] init];
        _values = [[NSMutableArray alloc] init];
    }
    
    return self;
}

@end

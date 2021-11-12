//
//  XPDeviceCPUUtil.h
//  Xposed
//
//  Created by Brian Tamsing on 10/29/21.
//

#ifndef XPDeviceCPUUtil_h
#define XPDeviceCPUUtil_h

#import <Foundation/Foundation.h>
#import "../Models/XPDeviceStat.h"

NS_ASSUME_NONNULL_BEGIN

@interface XPDeviceCPUUtil : NSObject // xcode currently failing on rename...should be named "XPDeviceUtil"

+ (instancetype)shared;

#pragma mark - Device Specs by Identifiers

- (int)getDeviceIntSpecWithTopLevelIdentifier:(int)topLevel secondLevel:(int)secondLevel;
- (NSString *)getDeviceStringSpecWithTopLevelIdentifier:(int)topLevel secondLevel:(int)secondLevel;


#pragma mark - Device Specs by sysctlbyname

- (int)getDeviceIntSpecByName:(const char *)name;
- (NSString *)getDeviceStringSpecByName:(const char *)name;


#pragma mark - Stat Retrievals

- (XPDeviceStat *)getCPUStats;
- (NSMutableArray<NSString*> *)getCPULoad;

- (XPDeviceStat *)getOSStats;
- (XPDeviceStat *)getVMStats;

@end

NS_ASSUME_NONNULL_END

#endif /* XPDeviceCPUUtil_h */

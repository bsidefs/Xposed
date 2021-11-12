//
//  XPDeviceStat.h
//  Xposed
//
//  Created by Brian Tamsing on 10/31/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XPDeviceStat : NSObject

@property (strong, nonatomic) NSUUID *id;
@property (strong, nonatomic) NSMutableArray<NSString*> *names;
@property (strong, nonatomic) NSMutableArray<NSString*> *values;

@end

NS_ASSUME_NONNULL_END

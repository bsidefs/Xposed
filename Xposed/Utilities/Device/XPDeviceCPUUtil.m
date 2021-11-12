//
//  XPDeviceCPUUtil.m
//  Xposed
//
//  Created by Brian Tamsing on 10/29/21.
//

#import <Foundation/Foundation.h>

#import <mach/mach.h>
#import <sys/types.h>
#import <sys/sysctl.h>

#import "XPDeviceCPUUtil.h"

#pragma mark - Macros

#define NBYTES_PER_KILOBYTE (1024)
#define NBYTES_PER_MEGABYTE (1024 * 1024)
#define NHZ_PER_MEGAHERTZ (1000000)

@implementation XPDeviceCPUUtil

+ (instancetype)shared {
    static XPDeviceCPUUtil *shared = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}


#pragma mark - Device Specs by Identifiers

- (int)getDeviceIntSpecWithTopLevelIdentifier:(int)topLevel secondLevel:(int)secondLevel {
    int mib[] = {
        topLevel,
        secondLevel
    };
    
    int spec;
    size_t len = sizeof(spec);
    
    sysctl(mib, 2, &spec, &len, NULL, 0);
    
    return spec;
}

- (NSString *)getDeviceStringSpecWithTopLevelIdentifier:(int)topLevel secondLevel:(int)secondLevel {
    int mib[] = {
        topLevel,
        secondLevel
    };
    
    char *spec;
    size_t len;
    
    sysctl(mib, 2, NULL, &len, NULL, 0);
    spec = malloc(len);
    
    sysctl(mib, 2, spec, &len, NULL, 0);
    
    NSString *result = [NSString stringWithUTF8String:spec];
    free(spec);
    
    return result;
}


#pragma mark - Device Specs by sysctlbyname

- (int)getDeviceIntSpecByName:(const char *)name {
    int spec;
    size_t len = sizeof(spec);
    
    sysctlbyname(name, &spec, &len, NULL, 0);
    return spec;
}

- (NSString *)getDeviceStringSpecByName:(const char *)name {
    char *spec;
    size_t len;
    
    sysctlbyname(name, NULL, &len, NULL, 0);
    spec = malloc(len);
    
    sysctlbyname(name, spec, &len, NULL, 0);
    
    NSString *result = [NSString stringWithUTF8String:spec];
    free(spec);
    
    return result;
}


#pragma mark - Stat Retrievals
// note: majority of stats require logic that makes even iteration not any better than gathering the data one by one

- (XPDeviceStat *)getCPUStats {
    XPDeviceStat *result = [[XPDeviceStat alloc] init];
    
    int archType = [self getDeviceIntSpecByName:"hw.cputype"];
    int archSubtype = [self getDeviceIntSpecByName:"hw.cpusubtype"];
    
    NSMutableString *arch = [[NSMutableString alloc] initWithString:@""];
    if (archType == CPU_TYPE_ARM64) {
        [arch appendString:@"arm64"];
        
        switch (archSubtype) {
        case CPU_SUBTYPE_ARM64E:
            [arch appendString:@"e"];
            break;
        case CPU_SUBTYPE_ARM64_V8:
            [arch appendString:@" v8"];
            break;
        }
    }
    
    [result.names addObject:@"Architecture"];
    [result.values addObject:arch];
    
    int ncpu = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_HW secondLevel:HW_NCPU];
    [result.names addObject:@"Cores"];
    [result.values addObject:[[[NSNumber alloc] initWithUnsignedInt:ncpu] stringValue]];
    
    
    NSMutableArray *load = [self getCPULoad];
    [result.names addObject:@"Load"];
    [result.values addObject:[NSString stringWithFormat:@"(%@, %@, %@)", load[0], load[1], load[2]]];
    
    [result.names addObject:@"Tasks"];
    [result.values addObject:load[3]];
    
    [result.names addObject:@"Threads"];
    [result.values addObject:load[4]];
    
    
    int byteOrder = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_HW secondLevel:HW_BYTEORDER];
    [result.names addObject:@"Byte Order"];
    [result.values addObject:[[[NSNumber alloc] initWithUnsignedInt:byteOrder] stringValue]];
    
    // -----------
    
    int cacheLine = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_HW secondLevel:HW_CACHELINE];
    [result.names addObject:@"Cache Line Size"];
    [result.values addObject:[NSString stringWithFormat:@"%u B", cacheLine]];
    
    // -----------
    
    int l1InstructionCacheSize = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_HW secondLevel:HW_L1ICACHESIZE];
    [result.names addObject:@"L1 Instruction Cache Size"];
    [result.values addObject:[NSString stringWithFormat:@"%u kB",
                              l1InstructionCacheSize / NBYTES_PER_KILOBYTE]];
    
    int l1DataCacheSize = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_HW secondLevel:HW_L1DCACHESIZE];
    [result.names addObject:@"L1 Data Cache Size"];
    [result.values addObject:[NSString stringWithFormat:@"%u kB",
                              l1DataCacheSize / NBYTES_PER_KILOBYTE]];
    
    int l2CacheSize = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_HW secondLevel:HW_L2CACHESIZE];
    [result.names addObject:@"L2 Cache Size"];
    [result.values addObject:[NSString stringWithFormat:@"%u MB",
                              l2CacheSize / NBYTES_PER_MEGABYTE]];
    
    int tbFreq = [self getDeviceIntSpecByName:"hw.tbfrequency"];
    [result.names addObject:@"Turbo Boost Frequency"];
    [result.values addObject:[NSString stringWithFormat:@"%u MHz",
                              tbFreq / NHZ_PER_MEGAHERTZ]];
    
    return result;
}

- (NSMutableArray<NSString*> *)getCPULoad {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    /*
     CPU usages:
        0 - user; CPU time used up by user-space programs
        1 - system; CPU time used up by the kernel
        2 - idle; CPU time that is currently not being used up
        3 - nice; a subset of user time. CPU time used by processes that have a positive "niceness," meaning a lower priority than other tasks
     */
    
    // load avgs
    int mib[] = {
        CTL_VM,
        VM_LOADAVG
    };
    
    struct loadavg load;
    size_t len = sizeof(load);
    
    if (sysctl(mib, 2, &load, &len, NULL, 0) == KERN_SUCCESS) {
        for (int i = 0; i < 3; i++) {
            NSString *ldavg = [[NSString alloc] initWithFormat:@"%.2f" locale:[NSLocale currentLocale], (double)load.ldavg[i]/load.fscale];
            [result addObject:ldavg];
        }
    } else {
        perror("Failed to get CPU load averages");
    }
    
    
    // task and thread counts
    host_t host = (host_t)mach_host_self();
    
    processor_set_name_t setName;
    processor_set_default(host, &setName);
    
    mach_msg_type_number_t count = PROCESSOR_SET_LOAD_INFO_COUNT;
    processor_set_info_t info = (processor_set_info_t) malloc(count);
    
    if (processor_set_statistics(setName, PROCESSOR_SET_LOAD_INFO, info, &count) == KERN_SUCCESS) {
        processor_set_load_info_t loadInfo = (processor_set_load_info_t)info;
        [result addObject:[[[NSNumber alloc] initWithInt:loadInfo->task_count] stringValue]];
        [result addObject:[[[NSNumber alloc] initWithInt:loadInfo->thread_count] stringValue]];
    }
    
    free(info);
    
    return result;
}

- (XPDeviceStat *)getOSStats {
    XPDeviceStat *result = [[XPDeviceStat alloc] init];
    
    NSString *osVersion = [[NSProcessInfo processInfo] operatingSystemVersionString];
    [result.names addObject:@"Version"];
    [result.values addObject:osVersion];
    
    NSString *kernelVersion = [self getDeviceStringSpecWithTopLevelIdentifier:CTL_KERN secondLevel: KERN_VERSION];
    NSString *kernelRelease = [self getDeviceStringSpecWithTopLevelIdentifier:CTL_KERN secondLevel: KERN_OSRELEASE];
    
    [result.names addObject:@"Kernel Version"];
    [result.values addObject:kernelVersion];

    [result.names addObject:@"Kernel Release"];
    [result.values addObject:kernelRelease];
    
    
    struct host_sched_info schedInfo;
    mach_msg_type_number_t count = HOST_SCHED_INFO_COUNT;
    
    NSString *minTimeout = @"", *minQuantum = @"";
    if (host_info(mach_host_self(), HOST_SCHED_INFO, (host_info_t)&schedInfo, &count) == KERN_SUCCESS) {
        minTimeout = [[NSString alloc] initWithFormat:@"%d ms" locale:[NSLocale currentLocale], schedInfo.min_timeout];
        minQuantum = [[NSString alloc] initWithFormat:@"%d ms" locale:[NSLocale currentLocale], schedInfo.min_quantum];
    }
    
    
    [result.names addObject:@"Scheduling Timeout (minimum)"];
    [result.values addObject:minTimeout];
    
    [result.names addObject:@"Scheduling Quantum (minimum)"];
    [result.values addObject:minQuantum];

    int maxVnodes = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_KERN secondLevel:KERN_MAXVNODES];
    [result.names addObject:@"Kernel Maximum Vnodes"];
    [result.values addObject:[NSString stringWithFormat:@"%u", maxVnodes]]; // factory methods no longer return autoreleased objects with ARC

    int maxProcs = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_KERN secondLevel:KERN_MAXPROC];
    [result.names addObject:@"Kernel Maximum Processes"];
    [result.values addObject:[NSString stringWithFormat:@"%u", maxProcs]];

    int maxOpenFilesPerProc = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_KERN secondLevel:KERN_MAXFILESPERPROC];
    [result.names addObject:@"Kernel Maximum Open Files (per process)"];
    [result.values addObject:[NSString stringWithFormat:@"%u", maxOpenFilesPerProc]];

    int hostId = [self getDeviceIntSpecWithTopLevelIdentifier:CTL_KERN secondLevel:KERN_HOSTID];
    [result.names addObject:@"Host ID"];
    [result.values addObject:[NSString stringWithFormat:@"%u", hostId]];
    
    return result;
}

- (XPDeviceStat *)getVMStats {
    struct vm_statistics stats;
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    
    /*
     - "host" == what is executing the mach kernel
     - represented in two parts:
        1. name port, "host," used to query info
        2. control port, "host_priv," used to manipulate it
     */
    
    XPDeviceStat *result = [[XPDeviceStat alloc] init];
    if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&stats, &count) == KERN_SUCCESS) {
        [result.names addObject:@"Reactivations"];
        NSNumber *reactivations = [[NSNumber alloc] initWithUnsignedInt:stats.reactivations];
        [result.values addObject:[reactivations stringValue]];
        
        [result.names addObject:@"Page-ins"];
        NSNumber *pageins = [[NSNumber alloc] initWithUnsignedInt:stats.pageins];
        [result.values addObject:[pageins stringValue]];
        
        [result.names addObject:@"Page-outs"];
        NSNumber *pageouts = [[NSNumber alloc] initWithUnsignedInt:stats.pageouts];
        [result.values addObject:[pageouts stringValue]];
        
        [result.names addObject:@"Faults"];
        NSNumber *faults = [[NSNumber alloc] initWithUnsignedInt:stats.faults];
        [result.values addObject:[faults stringValue]];
        
        [result.names addObject:@"COW Faults"];
        NSNumber *cowFaults = [[NSNumber alloc] initWithUnsignedInt:stats.cow_faults];
        [result.values addObject:[cowFaults stringValue]];
        
    } else {
        perror("[!] Failed to obtain virtual memory statistics");
    }
    
    return result;
}

@end

//
//  XPSpecDetailViewModel.swift
//  Xposed
//
//  Created by Brian Tamsing on 10/30/21.
//

import SwiftUI
import Combine

final class XPSpecDetailViewModel: ObservableObject {
    var selection: XPDeviceSpec
    
    @Published var stat = XPDeviceStat()
    
    private var cancellable: Cancellable?
    private let cpuUtil = XPDeviceCPUUtil.shared()
    
    
    init(selection: XPDeviceSpec) {
        self.selection = selection
    }
    
    
    func getSpecs() {
        switch selection {
            case .cpu:
                getDeviceCPUSpecs()
                
            case .os:
                getDeviceOSStats()
                
            case .memory:
                getDeviceVMStats()
                
            case .device:
                print("device")
                
            default:
                break
        }
    }
    
    func getDeviceCPUSpecs() {
        print("[+] Exposing device CPU information...")
        stat = cpuUtil.getCPUStats()
        print("[+] Finished.\n")
    }
    
    func getDeviceOSStats() {
        print("[+] Exposing device OS information...")
        stat = cpuUtil.getOSStats()
        
        // uptime config...
        stat.names.add("Uptime")
        
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .abbreviated
        dateFormatter.maximumUnitCount = 3
        
        if let uptime = dateFormatter.string(from: ProcessInfo.processInfo.systemUptime) {
            stat.values.add(uptime)
        }
        
        // update uptime while on screen
        cancellable = Timer.publish(every: 1, tolerance: 0.3, on: .main, in: .common)
            .autoconnect()
            .sink { [unowned self] _ in
                if let uptime = dateFormatter.string(from: ProcessInfo.processInfo.systemUptime) {
                    self.stat.values.removeLastObject()
                    self.stat.values.add(uptime)
                }
            }
        
        print("[+] Finished.\n")
    }
    
    func getDeviceVMStats() {
        print("[+] Exposing device VM information...")
        stat = cpuUtil.getVMStats()
        print("[+] Finished.\n")
    }
    
    
    deinit {
        self.cancellable?.cancel()
    }
}

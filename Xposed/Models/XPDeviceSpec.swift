//
//  XPDeviceSpec.swift
//  Xposed
//
//  Created by Brian Tamsing on 10/31/21.
//

import Foundation

struct XPDeviceSpec: Identifiable, Equatable {
    let id = UUID()
    
    let name: String
    let imageName: String
    let nsID: String
    
    static let cpu = XPDeviceSpec(name: "CPU", imageName: "cpu", nsID: "cpuAnimation")
    static let os = XPDeviceSpec(name: "OS", imageName: "iphone", nsID: "osAnimation")
    static let memory = XPDeviceSpec(name: "Memory", imageName: "memorychip", nsID: "memoryAnimation")
    static let device = XPDeviceSpec(name: "Device", imageName: "info.circle", nsID: "deviceAnimation")
    
    static let all = [cpu, os, memory, device]
}

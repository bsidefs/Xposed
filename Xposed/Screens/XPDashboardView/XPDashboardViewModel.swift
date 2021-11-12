//
//  XPDashboardViewModel.swift
//  Xposed
//
//  Created by Brian Tamsing on 10/29/21.
//

import Foundation

final class XPDashboardViewModel: ObservableObject {
    var selection: XPDeviceSpec?
    @Published var isShowingSpecDetailView = false
}

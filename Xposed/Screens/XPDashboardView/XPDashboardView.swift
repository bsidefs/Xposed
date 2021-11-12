//
//  XPDashboardView.swift
//  Xposed
//
//  Created by Brian Tamsing on 10/29/21.
//

import SwiftUI

struct XPDashboardView: View {
    @StateObject var viewModel = XPDashboardViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var isLightMode: Bool {
        colorScheme == .light ? true : false
    }
    
    @Namespace var ns
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Dashboard")
                        .font(.system(size: 30))
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                
                if !viewModel.isShowingSpecDetailView {
                    List(XPDeviceSpec.all) { spec in
                        XPDeviceSpecView(
                            isShowingSpecDetailView: $viewModel.isShowingSpecDetailView,
                            selection: $viewModel.selection,
                            option: spec,
                            ns: ns
                        )
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                }
            }
            .padding(.top, 25)
            
            if viewModel.isShowingSpecDetailView {
                XPSpecDetailView(
                    viewModel: XPSpecDetailViewModel(selection: viewModel.selection!),
                    isShowingSpecDetailView: $viewModel.isShowingSpecDetailView,
                    ns: ns)
            }
        }
        .statusBar(hidden: viewModel.isShowingSpecDetailView ? true : false)
    }
}

struct XPDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        XPDashboardView()
    }
}

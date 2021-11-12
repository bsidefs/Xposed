//
//  XPDeviceSpecView.swift
//  Xposed
//
//  Created by Brian Tamsing on 10/31/21.
//

import SwiftUI

struct XPDeviceSpecView: View {
    @Binding var isShowingSpecDetailView: Bool
    @Binding var selection: XPDeviceSpec?
    
    let option: XPDeviceSpec
    var ns: Namespace.ID
    
    @Environment(\.colorScheme) var colorScheme
    var isLightMode: Bool {
        colorScheme == .light ? true : false
    }
    
    var body: some View {
        Button {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.8)
            ){
                selection = option
                isShowingSpecDetailView = true
            }
        } label: {
            HStack(spacing: 15) {
                Image(systemName: option.imageName)
                Text(option.name)
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.horizontal)
            .background(isLightMode ? .black : Color(uiColor: .secondarySystemBackground))
            .foregroundColor(.white)
            .cornerRadius(5)
            .matchedGeometryEffect(id: option.nsID, in: ns, properties: .position, isSource: true)
        }
        .tint(.primary)
    }
}

//struct XPDeviceSpecOption_Previews: PreviewProvider {
//    static var previews: some View {
//        XPDeviceSpecOption()
//    }
//}

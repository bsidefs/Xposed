//
//  XPSpecDetailView.swift
//  Xposed
//
//  Created by Brian Tamsing on 10/30/21.
//

import SwiftUI

struct XPSpecDetailView: View {
    @ObservedObject var viewModel: XPSpecDetailViewModel
    @Binding var isShowingSpecDetailView: Bool
    
    var ns: Namespace.ID
    let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
    
    @Environment(\.colorScheme) var colorScheme
    
    var isLightMode: Bool {
        return colorScheme == .light ? true : false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 15) {
                Image(systemName: viewModel.selection.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(viewModel.selection.name)
                    .font(.system(size: 18))
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, windowScene.windows.first!.safeAreaInsets.top + 5)
            .padding(.bottom, 15)
            .background(isLightMode ? .black : Color(uiColor: .secondarySystemBackground))
            .foregroundColor(.white)
            .matchedGeometryEffect(id: viewModel.selection.nsID, in: ns, properties: .position, isSource: false)
            
            List(0..<viewModel.stat.names.count, id: \.self) { i in
                HStack(alignment: .top) {
                    Text(viewModel.stat.names[i] as! String) // '!' safe since these are statically typed as being NSStrings in the stat's interface
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text(viewModel.stat.values[i] as! String)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .listStyle(.plain)
        }
        .background(Color(uiColor: .systemBackground))
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            Button {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                ){
                    isShowingSpecDetailView = false
                }
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 55, height: 55)
                    .background(isLightMode ? .black : Color(uiColor: .secondarySystemBackground))
                    .foregroundColor(.white)
                    .font(Font.system(size: 18, weight: .medium))
                    .mask(Circle())
                    .shadow(color: Color.primary.opacity(0.1), radius: 10)
            }
        }
        .onAppear {
            viewModel.getSpecs()
        }
    }
}

//struct XPSpecDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        XPSpecDetailView(isShowingSpecDetailView: .constant(true))
//    }
//}

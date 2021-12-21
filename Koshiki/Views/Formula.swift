//
//  Formula.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/21.
//

import SwiftUI

struct Formula: View {
    @Binding var formulaSVG: String
    @Binding var formulaRect: (CGFloat, CGFloat)
    @Binding var errorMessage: String
    
    var body: some View {
        ZStack {
            if !formulaSVG.isEmpty {
                WebView(htmlSource: "<html>\(HTMLSource.head(title: "Formula"))<body>\(formulaSVG)</body></html>")
                    .frame(width: formulaRect.0, height: formulaRect.1)
                    .blur(radius: errorMessage.isEmpty ? 0 : 2)
                    .animation(.easeOut, value: errorMessage.isEmpty)
            }
        }
        .padding(Metrics.padding)
        .padding(.trailing, Metrics.padding)
        .frame(height: Metrics.windowHeight-16)
        .background(EffectView(material: .contentBackground, blendingMode: .behindWindow))
        .cornerRadius(8, antialiased: true)
        .frame(width: formulaRect.0 + 2*Metrics.padding + 2, alignment: .leading)
        .clipped()
    }
}

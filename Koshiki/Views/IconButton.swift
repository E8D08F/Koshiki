//
//  IconButton.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/20.
//

import SwiftUI

struct IconButton: View {
    @State private var hover = false
    
    let name: String
    let colour: Color = .primary
    
    var body: some View {
        Image(name)
            .resizable()
            .padding(2)
            .foregroundColor(colour.opacity(hover ? 0.8 : 0.3))
            .background(Color.black.opacity(hover ? 0.1 : 0.05))
            .frame(width: 18, height: 18)
            .cornerRadius(3)
            .onHover { hovering in
                withAnimation(.easeOut) {
                    hover = hovering
                }
            }
    }
}

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
    let help: String
    let disabled: Bool
    let colour: Color
    let perfom: () -> ()
    
    var body: some View {
        Image(name)
            .resizable()
            .padding(2)
            .foregroundColor(colour.opacity(hover ? 1 : 0.4))
            .frame(width: 18, height: 18)
            .cornerRadius(3)
            .help(disabled ? "" : help)
            .onHover { hovering in
                if disabled { return }
                
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
                
                withAnimation(.easeOut) {
                    hover = hovering
                }
            }
            .onTapGesture { if !disabled { perfom() } }
    }
    
    init(_ name: String, colour: Color = .primary, help: String = "", disabled: Bool = false, perfom: @escaping () -> () = {}) {
        self.name = name
        self.colour = colour
        self.help = help
        self.disabled = disabled
        self.perfom = perfom
    }
}

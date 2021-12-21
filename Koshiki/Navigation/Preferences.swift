//
//  Preferences.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/19.
//

import SwiftUI

struct Preferences: View {
    @AppStorage(PreferenceType.embracingNotes) var embracingNotes: PreferenceType.EmbracingNotes = .dollars
    @AppStorage(PreferenceType.customSVGExportPath) var customSVGExportPath: String = ""
    @AppStorage(PreferenceType.svgexportRawArguments) var svgexportRawArguments: String = ""
    
    var body: some View {
        TabView {
            Form {
                Picker("Embracing Notes:", selection: $embracingNotes) {
                    Text("$$")
                        .tag(PreferenceType.EmbracingNotes.dollars)
                    Text("\\(\\)")
                        .tag(PreferenceType.EmbracingNotes.slashBrackets)
                }
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("General")
            }
            
            Form {
                TextField("Custom svgexport Path:", text: $customSVGExportPath, prompt: Text(PreferenceType.svgexportPathDefault))
                TextField("svgexport Arguments:", text: $svgexportRawArguments, prompt: Text(PreferenceType.svgexportRawArgumentsDefault))
            }
            .tabItem {
                Image(systemName: "terminal")
                Text("Advanced")
            }
        }
        .padding()
        .frame(width: Metrics.preferenceWindowWidth, height: Metrics.preferenceWindowHeight)
    }
}

class PreferenceType {
    enum EmbracingNotes: Int, Identifiable {
        case dollars, slashBrackets
        
        var id: Int { rawValue }
    }
    
    static let embracingNotes = "embracingNotes"
    static let customSVGExportPath = "customSVGExportPath"
    static let svgexportRawArguments = "svgexportRawArguments"
    
    static let svgexportPathDefault = "/usr/local/bin"
    static let svgexportRawArgumentsDefault = "1.5x"
}

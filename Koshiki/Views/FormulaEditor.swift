//
//  FormulaEditor.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/21.
//

import SwiftUI

struct FormulaEditor: View {
    @Environment(\.hostingWindow) var hostingWindow
    @State private var formulaWindow: NSWindow!
    
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage(PreferenceType.embracingNotes) var embracingNotes: PreferenceType.EmbracingNotes = .dollars
    @AppStorage(PreferenceType.customSVGExportPath) var customSVGExportPath: String = ""
    @AppStorage(PreferenceType.svgexportRawArguments) var svgexportRawArguments: String = ""
    
    struct HistoryFormula: Identifiable, Codable {
        var id = UUID()
        let raw: String
    }
    @AppStorage("historyFormulae") var historyFormulae: [HistoryFormula] = []
    
    enum Field: Hashable {
        case formula, web
    }
    @State private var rawFormula: String = ""
    @FocusState private var field: Field?
    
    @State private var formula: String = ""
    @State private var formulaSVG: String = ""
    @State private var formulaSVGOriginal: String = ""
    @State private var formulaRect: (CGFloat, CGFloat) = (0, 0)
    
    @State private var errorMessage: String = ""
    
    let timingFunction = CAMediaTimingFunction(controlPoints: 0.65, 0, 0.35, 1)
    
    var formulaField: some View {
        TextField("\\Koshiki{...}", text: $rawFormula)
            .textFieldStyle(.plain)
            .padding(Metrics.padding)
            .focused($field, equals: .formula)
            .lineLimit(0)
            // Avoid being modified multiple times (like Typinator)
            .onChange(of: rawFormula) { _ in
                DispatchQueue.main.async {
                    formula = rawFormula
                    changeFormulaFrame()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                field = .formula
                changeFormulaFrame(withAnimation: false) {
                    panel.orderFrontRegardless()
                    panel.makeKey()
                    NSApp.unhide(nil)
                }
            }
            .onAppear {
                formulaWindow = AppDelegate.instance.formulaWindow

                let rootView = Formula(formulaSVG: $formulaSVG, formulaRect: $formulaRect, errorMessage: $errorMessage)
                formulaWindow.contentView = NSHostingView(rootView: rootView)
                panel.addChildWindow(formulaWindow, ordered: .below)
            }
    }
    
    var controls: some View {
        VStack {
            HStack(spacing: Metrics.padding / 4) {
                Spacer()
                
                if !formulaSVG.isEmpty && errorMessage.isEmpty {
                    IconButton("export", help: "Export") { exportToSVG() }
                }
                
                if !historyFormulae.isEmpty {
                    ZStack {
                        IconButton("history", help: "History")
                        
                        Menu("") {
                            ForEach(historyFormulae) { historyFormula in
                                Button(historyFormula.raw) {
                                    rawFormula = historyFormula.raw
                                }
                            }
                            
                            Divider()
                            
                            Button("Clear History") { historyFormulae = [] }
                        }
                        .menuStyle(BorderlessButtonMenuStyle())
                        .menuIndicator(.hidden)
                    }.frame(width: 18, height: 18)
                }
            }
            .padding(Metrics.padding / 2)
            
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    IconButton("bug", help: "Annoying, right?", disabled: errorMessage.isEmpty)
                        .opacity(errorMessage.isEmpty ? 0 : 1)
                    
                    Text("= \(errorMessage)")
                        .font(Font.caption)
                        .foregroundColor(.secondary)
                        .opacity(errorMessage.isEmpty ? 0 : 1)
                }
                .padding(Metrics.padding / 2)
                .padding(.trailing, 2)
            }
            .mask (
                HStack(spacing: 0) {
                    LinearGradient(colors: [
                        .black,
                        .black.opacity(0.924),
                        .black.opacity(0.707),
                        .black.opacity(0.383),
                        .black.opacity(0)   // sin(x * pi / 2)
                    ], startPoint: .trailing, endPoint: .leading)
                        .frame(width: Metrics.padding / 4 * 3)

                    Rectangle()

                    LinearGradient(colors: [
                        .black,
                        .black.opacity(0.924),
                        .black.opacity(0.707),
                        .black.opacity(0.383),
                        .black.opacity(0)   // sin(x * pi / 2)
                    ], startPoint: .leading, endPoint: .trailing)
                        .frame(width: Metrics.padding / 4 * 3)
                }
            )
        }
    }
    
    var svgPreview: some View {
        WebView(htmlSource: webSource, scripts: [
            WebView.Script(HTMLSource.postRender) { value, error in
                errorMessage = ""
                
                if let value = value as? Array<Any> {
                    if let message = value[0] as? String {
                        errorMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !errorMessage.isEmpty { return }
                    }
                    
                    if let svg = value[1] as? Array<Any> {
                        if svg.isEmpty { return }
                        
                        formulaRect.0 = svg[0] as! Double
                        formulaRect.1 = svg[1] as! Double
                        formulaSVG = formula.isEmpty ? "" : svg[2] as! String
                        formulaSVGOriginal = formula.isEmpty ? "" : svg[3] as! String
                    }
                } else if let error = error { print(error) }
            }
        ]).hidden()
    }
    
    var invisibleButtonGroup: some View {
        Group {
            Button("", action: exportToSVG)
                .keyboardShortcut("e", modifiers: [.command])

            Button("", action: copyFormula)
                .keyboardShortcut(.return, modifiers: [.command])
            
            Button("") { NSApp.hide(nil) }
                .keyboardShortcut(.escape, modifiers: [])
        }.hidden()
    }
    
    var body: some View {
        ZStack {
            controls
            
            formulaField
            
            svgPreview
            
            invisibleButtonGroup
        }
            .font(.body.monospaced())
            .frame(minWidth: Metrics.windowWidth + extraWidth, maxWidth: Metrics.windowWidth + extraWidth)
            .frame(height: Metrics.windowHeight)
            .ignoresSafeArea()
            .frame(height: Metrics.windowHeight - Metrics.titlebarHeight)
            .background(
                ZStack {
                    EffectView(material: .menu, blendingMode: .behindWindow).ignoresSafeArea()
                    
                    Image("Grain")
                        .blendMode(.overlay)
                }
            )
    }
}

extension FormulaEditor {
    private var panel: NSWindow! { self.hostingWindow() }
    
    private var extraWidth: CGFloat {
        let delta = rawFormula.count - 13 >= 0 ? rawFormula.count - 12 : 0
        
        return CGFloat(delta) * 8
    }
    
    private var webSource: String {
        "<html>\(HTMLSource.head(title: "Hidden"))<body style='color:rgba(0,0,0,0);'><div id='coloured'>\\[\\color{\(colorScheme == .light ? "black" : "white")} \(formula)\\]</div><div id='original'>\\[\(formula)\\]</div></body></html>"
    }
    
    private func clean() {
        rawFormula = ""
        formula = ""
        formulaSVG = ""
        formulaSVGOriginal = ""
        errorMessage = ""
    }
    
    private func save() {
        if historyFormulae.last == nil || historyFormulae.last!.raw != rawFormula {
            historyFormulae.insert(HistoryFormula(raw: rawFormula), at: 0)
            
            if historyFormulae.count > 5 {
                let _ = historyFormulae.popLast()
            }
        }
        
        clean()
        
        NSApp.hide(nil)
    }
    
    private func copyFormula() {
        if formula != "" {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            var embraced: String
            
            switch embracingNotes {
            case .dollars:
                embraced = "$\(formula)$"
            case .slashBrackets:
                embraced = "\\(\(formula)\\)"
            }
            
            pasteboard.setString(embraced, forType: .string)

            save()
        }
    }

    private func exportToSVG() {
        if formula != "" {
            let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("Koshiki", isDirectory: true)
            if !FileManager.default.fileExists(atPath: tempDirectory.path) {
                do {
                    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
                } catch { print(error) }
            }
            
            let filename = tempDirectory.appendingPathComponent("formula.svg")
            do {
                try formulaSVGOriginal.write(to: filename, atomically: true, encoding: .utf8)
                
                system("export PATH=$PATH:\(customSVGExportPath.isEmpty ? PreferenceType.svgexportPathDefault : customSVGExportPath) && svgexport formula.svg formula.png \(svgexportRawArguments.isEmpty ? PreferenceType.svgexportRawArgumentsDefault : svgexportRawArguments)", directoryURL: tempDirectory)
                
                system("open .", directoryURL: tempDirectory)
                
                save()
            } catch { print(error) }
        }
    }
    
    private func changeFormulaFrame(withAnimation: Bool = true, doAfter: @escaping () -> () = {}) {
        let frame = panel.frame
        let svgWidth = formulaRect.0
        
        NSAnimationContext.runAnimationGroup { context in
            context.timingFunction = timingFunction
            context.completionHandler = doAfter

            (withAnimation ? formulaWindow.animator() : formulaWindow).setFrame(NSRect(x: frame.minX - svgWidth - 2*Metrics.padding + 2,
                                                     y: frame.minY+8,
                                                     width: svgWidth + 2*Metrics.padding,
                                                     height: formulaWindow.frame.height),
                                              display: true, animate: true)
        }
    }
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }
    }
}

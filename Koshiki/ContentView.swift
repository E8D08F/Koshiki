//
//  ContentView.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/18.
//

import SwiftUI


struct ContentView: View {
    enum Field: Hashable {
        case formula, web
    }
    
    @AppStorage(PreferenceType.embracingNotes) var embracingNotes: PreferenceType.EmbracingNotes = .dollars
    @AppStorage(PreferenceType.customSVGExportPath) var customSVGExportPath: String = ""
    @AppStorage(PreferenceType.svgexportRawArguments) var svgexportRawArguments: String = ""

    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.hostingWindow) var hostingWindow

    @State private var formula: String = ""
    @State private var rawFormula: String = ""
    @FocusState private var field: Field?
    
    @State private var formulaSVG: String = ""
    @State private var formulaRect: (CGFloat, CGFloat) = (0, 0)
    
    @State private var formulaWindow: NSWindow!
    
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
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showFormulaPanel"))) { _ in
                field = .formula
            }
            .onAppear {
                formulaWindow = AppDelegate.instance.formulaWindow

                let rootView = Formula(formulaSVG: $formulaSVG, formulaRect: $formulaRect)
                formulaWindow.contentView = NSHostingView(rootView: rootView)
                panel.addChildWindow(formulaWindow, ordered: .below)
            }
    }
    
    var extraWidth: CGFloat {
        let delta = rawFormula.count - 13 >= 0 ? rawFormula.count - 12 : 0
        
        return CGFloat(delta) * 8
    }
    
    var buttons: some View {
        VStack {
            HStack(spacing: Metrics.padding / 4) {
                IconButton(name: "escape")
                    .onTapGesture {
                        NSCursor.unhide()
                        NSApp.hide(nil)
                    }
                
                Spacer()
                
                IconButton(name: "export")
                    .onTapGesture { exportToSVG() }
                    .opacity(formulaSVG.isEmpty || !errorMessage.isEmpty ? 0 : 1)
                    .animation(.easeOut, value: formulaSVG.isEmpty || !errorMessage.isEmpty)
                
                IconButton(name: "history")
                    .onTapGesture {
                        
                    }
            }
            
            Spacer()
        }
        .padding(Metrics.padding / 2)
    }
    

    var body: some View {
        ZStack {
            buttons
            
            formulaField
        
            VStack {
                Spacer()
                
                if !errorMessage.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            IconButton(name: "bug")
                            
                            Text(" = \(errorMessage)")
                                .font(Font.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(Metrics.padding / 2)
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
                                .frame(width: Metrics.padding / 2)

                            Rectangle()

                            LinearGradient(colors: [
                                .black,
                                .black.opacity(0.924),
                                .black.opacity(0.707),
                                .black.opacity(0.383),
                                .black.opacity(0)   // sin(x * pi / 2)
                            ], startPoint: .leading, endPoint: .trailing)
                                .frame(width: Metrics.padding / 2)
                        }
                    )
                }
            }
            
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
                        }
                    } else if let error = error { print(error) }
                }
            ]).hidden()
            
            Group {
                Button("", action: exportToSVG)
                    .keyboardShortcut("e", modifiers: [.command])

                Button("", action: copyFormula)
                    .keyboardShortcut(.return, modifiers: [.command])
                
                Button("") { NSApp.hide(nil) }
                    .keyboardShortcut(.escape, modifiers: [])
            }.hidden()
        }
            .font(.body.monospaced())
            
            .frame(minWidth: Metrics.windowWidth + extraWidth, maxWidth: Metrics.windowWidth + extraWidth)
            .frame(height: Metrics.windowHeight)
            .ignoresSafeArea()
            .frame(height: Metrics.windowHeight - Metrics.titlebarHeight)
            .background(
                ZStack {
                    EffectView(material: .popover, blendingMode: .behindWindow).ignoresSafeArea()
                    
                    Image("Grain")
                        .blendMode(.overlay)
                }
            )
    }

    func copyFormula() {
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

            formula = ""
            formulaSVG = ""
            errorMessage = ""
            NSApp.hide(nil)
        }
    }

    func exportToSVG() {
        if formula != "" {
            let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("Koshiki", isDirectory: true)
            if !FileManager.default.fileExists(atPath: tempDirectory.path) {
                do {
                    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
                } catch { print(error) }
            }
            
            let filename = tempDirectory.appendingPathComponent("formula.svg")
            do {
                try formulaSVG.write(to: filename, atomically: true, encoding: .utf8)
                
                system("export PATH=$PATH:\(customSVGExportPath.isEmpty ? PreferenceType.svgexportPathDefault : customSVGExportPath) && svgexport formula.svg formula.png \(svgexportRawArguments.isEmpty ? PreferenceType.svgexportRawArgumentsDefault : svgexportRawArguments)", directoryURL: tempDirectory)
                
                system("open .", directoryURL: tempDirectory)
                
                formula = ""
                formulaSVG = ""
                errorMessage = ""
                NSApp.hide(nil)
            } catch { print(error) }
        }
    }
}

struct Formula: View {
    @Binding var formulaSVG: String
    @Binding var formulaRect: (CGFloat, CGFloat)
    
    var body: some View {
        ZStack {
            if !formulaSVG.isEmpty {
                WebView(htmlSource: "<html>\(HTMLSource.head(title: "Formula"))<body>\(formulaSVG)</body></html>")
                    .frame(width: formulaRect.0, height: formulaRect.1)
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

func system(_ command: String, directoryURL: URL? = nil) {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    
    task.currentDirectoryURL = directoryURL
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.arguments = ["-c", command]
    
    try! task.run()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    print("Koshiki", String(data: data, encoding: .utf8)!)
}

extension ContentView {
    private var panel: NSWindow! { self.hostingWindow() }
    
    var webSource: String {
        "<html>\(HTMLSource.head(title: "Hidden"))<body style='color:rgba(0,0,0,0);'>\\[\\color{\(colorScheme == .light ? "black" : "white")} \(formula)\\]</body></html>"
    }
    
    func changeFormulaFrame() {
        let frame = panel.frame
        
        NSAnimationContext.runAnimationGroup { context in
            context.timingFunction = timingFunction
            
            formulaWindow.animator().setFrame(NSRect(x: frame.minX - formulaRect.0 - 2*Metrics.padding + 2,
                                                     y: frame.minY+8,
                                                     width: formulaRect.0 + 2*Metrics.padding,
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

//
//  KoshikiApp.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/18.
//

import SwiftUI
import KeyboardShortcuts

@main
struct KoshikiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {}
            .commands {
                CommandGroup(replacing: .appInfo) {
                    Button("About Koshiki") { }
                }
                
                CommandGroup(replacing: .newItem) { }
            }
        
        Settings { Preferences() }
    }
}
class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var instance: AppDelegate! = nil
    var panel: NSWindow!
    var formulaWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self
        
        panel = NSApp.windows.first!
        
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        
        // Allow it to appear in fullscreen
        panel.collectionBehavior.insert(.fullScreenAuxiliary)  // Working with NSPanel
        panel.center()
        
        let frame = panel.frame
        formulaWindow = NSWindow(contentRect: NSRect(x: frame.minX - 2*Metrics.padding + 2,
                                                     y: frame.minY+8,
                                                     width: 0, height: 0),
                                 styleMask: [.fullSizeContentView],
                                 backing: .buffered, defer: false)
        
        formulaWindow.orderOut(nil)
        formulaWindow.setAnchorAttribute(.trailing, for: .horizontal)
        formulaWindow.isMovable = false
        formulaWindow.backgroundColor = .clear
        formulaWindow.hidesOnDeactivate = false
        
        let rootView = ContentView()
            .environment(\.hostingWindow, { [weak panel] in
            return panel
        })
        panel.contentView = NSHostingView(rootView: rootView)
        
        KeyboardShortcuts.onKeyUp(for: .showFormulaPanel) {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

extension KeyboardShortcuts.Name {
    static let showFormulaPanel = Self("showFormulaPanel", default: Shortcut(.space, modifiers: [.option]))
}

// Allow window access in Views
struct HostingWindowKey: EnvironmentKey {
    static let defaultValue: () -> NSWindow? = { nil }
}

extension EnvironmentValues {
    var hostingWindow: () -> NSWindow? {
        get { self[HostingWindowKey.self] }
        set { self[HostingWindowKey.self] = newValue }
    }
}

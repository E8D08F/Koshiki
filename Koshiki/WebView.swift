//
//  WebView.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/19.
//

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    typealias ScriptCompletion = (Any?, Error?) -> ()
    let htmlSource: String
    
    struct Script {
        enum T {
            case file(String, WKUserScriptInjectionTime)
            case plain(String, ScriptCompletion)
        }
        
        let type: T
        
        init(name: String, injectionTime: WKUserScriptInjectionTime) {
            self.type = .file(name, injectionTime)
        }
        
        init(_ plain: String, handler: @escaping ScriptCompletion) {
            self.type = .plain(plain, handler)
        }
    }
    
    let scripts: [Script]
    
    func makeNSView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        
        let view = WKWebView(frame: .zero, configuration: config)
        view.setValue(false, forKey: "drawsBackground")
        view.navigationDelegate = context.coordinator
        
        scripts.forEach { script in
            switch script.type {
            case .file(let filename, let injectionTime):
                guard let path = Bundle.main.path(forResource: filename, ofType: "js"),
                      let source = try? String(contentsOfFile: path) else {
                    print("Cannot not load: \(filename).js")
                    return
                }
                
                let userScript = WKUserScript(source: source,
                                              injectionTime: injectionTime, forMainFrameOnly: true)
                controller.addUserScript(userScript)
            default: break
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlSource, baseURL: nil)
    }
    
    init(htmlSource: String, scripts: [Script] = []) {
        self.htmlSource = htmlSource
        self.scripts = scripts
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(scripts: scripts) }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let scripts: [Script]
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                            decisionHandler: @escaping (WKNavigationActionPolicy) -> ()) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    NSWorkspace.shared.open(url)
                }
            } else { decisionHandler(.allow) }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            scripts.forEach { script in
                switch script.type {
                case .plain(let plain, let completion):
                    webView.evaluateJavaScript(plain, completionHandler: completion)
                default: break
                }
            }
        }
        
        init(scripts: [Script]?) { self.scripts = scripts ?? [] }
    }
}

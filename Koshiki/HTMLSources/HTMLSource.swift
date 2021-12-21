//
//  HTMLSource.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/19.
//

import Foundation

class HTMLSource {
    static var style: String {
        if let path = Bundle.main.path(forResource: "style", ofType: "css"),
           let str = try? String(contentsOfFile: path) {
            return str
        }
        
        return ""
    }
    
    static var postRender: String {
        if let path = Bundle.main.path(forResource: "postRender", ofType: "js"),
           let str = try? String(contentsOfFile: path) {
            return str
        }
        
        return ""
    }
    
    static func head(title: String) -> String {
        if let path = Bundle.main.path(forResource: "head", ofType: "html"),
           let content = try? String(contentsOfFile: path) {
            return "<head><title>\(title)</title>\(content)<style>\(style)</style></head>"
        }
        
        return "<head><style>\(style)</style></head>"
    }
}

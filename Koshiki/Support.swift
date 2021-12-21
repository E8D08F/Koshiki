//
//  Support.swift
//  Koshiki
//
//  Created by Toto Minai on 2021/12/21.
//

import Foundation

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

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let json = try? JSONDecoder().decode([Element].self, from: data) else {
                  return nil
              }
        
        self = json
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let json = String(data: data, encoding: .utf8) else {
                  return "[]"
              }
        
        return json
    }
}

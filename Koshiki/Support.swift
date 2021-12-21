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

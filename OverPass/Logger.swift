//
//  Logger.swift
//  OverPass
//
//  Comprehensive logging system with version tracking
//  Includes debug log download functionality
//

import Foundation
import AppKit

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

class Logger: ObservableObject {
    static let shared = Logger()
    
    @Published var copyConfirmationMessage: String? = nil
    
    private var logEntries: [LogEntry] = []
    private let logQueue = DispatchQueue(label: "com.overpass.logger", attributes: .concurrent)
    private let maxLogEntries = 10000 // Keep last 10k entries
    
    private init() {
        log("Logger initialized - Version: \(AppVersion.current)", level: .info)
    }
    
    struct LogEntry {
        let timestamp: Date
        let level: LogLevel
        let message: String
        let version: String
        
        var formatted: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return "[\(formatter.string(from: timestamp))] [\(version)] [\(level.rawValue)] \(message)"
        }
    }
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let detailedMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        logQueue.async(flags: .barrier) {
            let entry = LogEntry(
                timestamp: Date(),
                level: level,
                message: detailedMessage,
                version: AppVersion.current
            )
            
            // Print to console
            print(entry.formatted)
            
            // Store in memory
            self.logEntries.append(entry)
            
            // Keep only last maxLogEntries
            if self.logEntries.count > self.maxLogEntries {
                self.logEntries.removeFirst(self.logEntries.count - self.maxLogEntries)
            }
        }
    }
    
    func getLogEntries() -> [LogEntry] {
        return logQueue.sync {
            return Array(logEntries)
        }
    }
    
    func copyDebugLogsToClipboard() {
        log("User requested debug logs copy to clipboard", level: .info)
        
        let entries = getLogEntries()
        let logContent = entries.map { $0.formatted }.joined(separator: "\n")
        
        let header = """
        ========================================
        OverPass Debug Logs
        Version: \(AppVersion.current)
        Generated: \(Date())
        Total Entries: \(entries.count)
        ========================================
        
        """
        
        let fullLog = header + logContent
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullLog, forType: .string)
        
        log("Debug logs copied to clipboard - \(entries.count) entries", level: .info)
        
        // Show temporary confirmation message
        DispatchQueue.main.async {
            self.copyConfirmationMessage = "Logs copied to clipboard"
            
            // Clear message after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.copyConfirmationMessage = nil
            }
        }
    }
    
    func clearLogs() {
        logQueue.async(flags: .barrier) {
            self.logEntries.removeAll()
            self.log("Logs cleared", level: .info)
        }
    }
}

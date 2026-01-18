//
//  AppVersion.swift
//  OverPass
//
//  Version management - reads from version.txt file
//  Format: MAJOR.MINOR.PATCH (e.g., 1.0.0)
//

import Foundation

struct AppVersion {
    static var current: String {
        // Try to read from bundle first (set by build script)
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        
        // Fallback: try to read from version.txt in bundle
        if let versionPath = Bundle.main.path(forResource: "version", ofType: "txt"),
           let versionString = try? String(contentsOfFile: versionPath, encoding: .utf8) {
            return versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Final fallback
        return "1.0.0"
    }
    
    static func incrementPatch() -> String {
        let components = current.split(separator: ".").map { Int($0) ?? 0 }
        let major = components.count > 0 ? components[0] : 1
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0
        
        return "\(major).\(minor).\(patch + 1)"
    }
    
    static func incrementMinor() -> String {
        let components = current.split(separator: ".").map { Int($0) ?? 0 }
        let major = components.count > 0 ? components[0] : 1
        let minor = components.count > 1 ? components[1] : 0
        
        return "\(major).\(minor + 1).0"
    }
}

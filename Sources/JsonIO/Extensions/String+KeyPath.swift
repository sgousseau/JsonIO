//
//  String+KeyPath.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//

public struct KeyPath {
    var segments: [String]
    
    var isEmpty: Bool { segments.isEmpty }
    
    var path: String { segments.joined(separator: ".") }
    
    func headAndTail() -> (head: String, tail: KeyPath)? {
        guard !isEmpty else { return nil }
        var tail = segments
        let head = tail.removeFirst()
        return (head, KeyPath(segments: tail))
    }
}

public extension KeyPath {
    init(_ string: String) {
        segments = string.components(separatedBy: ".")
    }
}

public extension String {
    var headAndTail: (head: String, tail: KeyPath)? {
        isEmpty ? nil : KeyPath(self).headAndTail()
    }
}

extension KeyPath: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
    public init(unicodeScalarLiteral value: String) {
        self.init(value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}

protocol StringProtocol {
    init(string s: String)
}

extension String: StringProtocol {
    init(string s: String) {
        self = s
    }
}

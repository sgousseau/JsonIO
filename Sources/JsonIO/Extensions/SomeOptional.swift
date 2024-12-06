//
//  SomeOptional.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//

import Foundation

public protocol SomeOptional {
    func isSome() -> Bool
    func unwrap() -> Any
}

extension Optional: SomeOptional {
    
    public func isSome() -> Bool {
        switch self {
        case .none: return false
        case .some: return true
        }
    }
    
    public func unwrap() -> Any {
        switch self {
        case .none: preconditionFailure("nil unwrap")
        case .some(let unwrapped): return unwrapped
        }
    }
}

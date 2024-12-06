//
//  Dictionary+KeyPath.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//

extension Dictionary where Key: StringProtocol {
    
    subscript(keyPath keyPath: KeyPath) -> Any? {
        get {
            guard let (head, tail) = keyPath.headAndTail() else {
                return nil
            }
            
            if tail.isEmpty {
                let key = Key(string: head)
                return self[key]
            }
            
            let key = Key(string: head)
            let next = self[key]
            
            guard let nestedDict = next as? [Key: Any] else {
                return next
            }
            
            return nestedDict[keyPath: tail]
        }
        set {
            guard let (head, tail) = keyPath.headAndTail() else {
                return
            }
            
            if tail.isEmpty {
                let key = Key(string: head)
                self[key] = newValue as? Value
                return
            }
            
            let key = Key(string: head)
            let value = self[key]
        
            if var nestedDict = value as? [Key: Any] {
                nestedDict[keyPath: tail] = newValue
                self[key] = nestedDict as? Value
            }
        }
    }
}

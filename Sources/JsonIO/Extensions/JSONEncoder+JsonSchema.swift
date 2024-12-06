//
//  JSONEncoder+JsonSchema.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//


import Foundation

public extension JSONEncoder {
    
    func encode<T>(_ object: T) throws -> Data where T: Encodable & JsonSchemaExpressible {
        try encode(object: object, schema: T.encodingSchema)
    }
    
    func encode<T, K>(_ object: T, _: K.Type = K.self) throws -> Data where T: Encodable, K: Encodable & JsonSchemaExpressible {
        try encode(object: object, schema: K.encodingSchema)
    }
}

public extension JSONEncoder {
    
    func encode<T>(_ object: T, schema: JsonSchema<T>) throws -> Data where T: Encodable {
        try encode(object: object, schema: schema)
    }
    
    func encode<T, K>(_ object: T, schema: JsonSchema<K>) throws -> Data where T: Encodable, K: Encodable {
        try encode(object: object, schema: schema)
    }
}

private extension JSONEncoder {
    
    func encode<T, K>(object: T, schema: JsonSchema<K>) throws -> Data where T: Encodable, K: Encodable {
        let value: Any = try buildJSON(object, schema: schema)
        var json = value
        
        if case .object = schema,
           let arrayOfDictionaries = value as? [[String: Any]] {
            // Le schema spécifie "object" et non "array", mais on a encodé une séquence, on tente probablement de représenter une collection hierarchisée par un ou plusieurs conteneurs, on doit réorganiser le JSON en un seul item.
            json = arrayOfDictionaries.compactMap { $0 }.mergingDictionaries()
        }
        
        return try serialize(json)
    }
    
    func serialize(_ json: Any) throws -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        } catch {
            throw JsonSchemaError.encoding("\(error)")
        }
    }
    
    func buildJSON<T, K>(_ object: T, schema: JsonSchema<K>) throws -> Any where T: Encodable, K: Encodable {
        var json: Any
        
        do {
            let data = try JSONEncoder().encode(object)
            json = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw JsonSchemaError.encoding("L'objet n'est pas sérialisable: \(error)")
        }
        
        if let someOptional = json as? SomeOptional, someOptional.isSome() {
            json = someOptional.unwrap()
        }
        
        guard let value = try formatJSON(json, schema: schema),
              let filteredValue = filterEmptyObjects(value)
        else {
            throw JsonSchemaError.encoding("L'objet encodé est nil")
        }
        
        return filteredValue
    }
    
    func formatJSON<T>(_ object: Any?, schema: JsonSchema<T>) throws -> Any? where T: Encodable {
        guard let object = object else {
            return [String: Any]()
        }
        
        var value: Any = object
        
        if let someOptional = value as? SomeOptional, someOptional.isSome() {
            value = someOptional.unwrap()
        }
        
        return switch schema {
            
        case let .object(key, properties) where key.isEmpty:
            try formatRootObject(value, properties: properties)
            
        case let .object(key, properties):
            try formatObject(value, key: key, properties: properties)
        
        case let .array(key, properties) where key.isEmpty:
            try formatRootArray(value, properties: properties)
            
        case let .array(key, properties):
            try formatArray(value, key: key, children: properties)
            
        case .allProperties:
            try formatAllProperties(object)
            
        case let .property(localKeyPath, remoteKeyPath, toArray):
            try formatProperty(value, localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray)
            
        case let .value(localKeyPath, remoteKeyPath, toArray):
            try formatValue(value, localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray)
        }
    }
    
    func formatRootObject<T>(_ object: Any?, properties: [JsonSchema<T>]) throws -> Any? where T: Encodable {
        if let array = object as? [Any] {
            return try array.map { a in try properties.compactMap { try formatJSON(a, schema: $0) }.mergingDictionaries() }
        } else {
            return try properties.compactMap { try formatJSON(object, schema: $0) }.mergingDictionaries()
        }
    }
    
    func formatRootArray<T>(_ object: Any?, properties: [JsonSchema<T>]) throws -> Any? where T: Encodable {
        if let array = object as? [Any] {
            return try array.map { a in try properties.compactMap { try formatJSON(a, schema: $0) }.mergingDictionaries() }.flatten()
        } else {
            return [try properties.compactMap { try formatJSON(object, schema: $0) }.mergingDictionaries()].flatten()
        }
    }
    
    func formatObject<T>(_ object: Any?, key: String, properties: [JsonSchema<T>]) throws -> Any? where T: Encodable {
        if let array = object as? [Any] {
            return try array.map { a in try properties.compactMap { try formatObject(a, key: key, property: $0) }.mergingDictionaries() }
        } else {
            return try properties.compactMap { try formatObject(object, key: key, property: $0) }.mergingDictionaries()
        }
    }
    
    func formatObject<T>(_ object: Any?, key: String, property: JsonSchema<T>) throws -> Any? where T: Encodable {
        guard let object = try formatJSON(object, schema: property) else {
            return [String: Any]()
        }
        
        if let someOptional = object as? SomeOptional, someOptional.isSome() {
            return [key: someOptional.unwrap()]
        } else {
            return [key: object]
        }
    }
    
    func formatArray<T>(_ object: Any?, key: String, children: [JsonSchema<T>]) throws -> Any? where T: Encodable {
        let map = try children.compactMap { try formatJSON(object, schema: $0) }
        let merged = map.mergingDictionaries()
        let result = [key: [merged].flatten()]
        return result
    }
    
    func formatAllProperties(_ object: Any?) throws -> Any? {
        guard let object = object else {
            throw JsonSchemaError.formating("Un objet nil ne peut pas être sérialisé.")
        }
        
        guard let dictionary = object as? [String: Any] else {
            return object
        }
        
        return dictionary
    }
    
    func formatProperty(_ object: Any?, localKeyPath: String, remoteKeyPath: String, toArray: Bool = false) throws -> Any? {
        guard let object = object else {
            throw JsonSchemaError.formating("Un objet nil ne peut pas être sérialisé.")
        }
        
        guard let dictionary = object as? [String: Any],
              let object = dictionary[keyPath: KeyPath(localKeyPath)] else {
            // Normal, on cherche dans le mauvais objet.
            return [String: Any]()
        }
        
        switch remoteKeyPath.headAndTail {
        case nil:
            return [String: Any]()
            
        case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
            let value = toArray ? [object] : object
            return [head: value]
            
        case let (head, remainingKeyPath)?:
            let value = try formatValue(object, localKeyPath: localKeyPath, remoteKeyPath: remainingKeyPath.path, toArray: toArray)
            return [head: value]
        }
    }
    
    func formatValue(_ object: Any?, localKeyPath: String, remoteKeyPath: String, toArray: Bool = false) throws -> Any? {
        guard let object = object else {
            throw JsonSchemaError.formating("Un objet nil ne peut pas être sérialisé.")
        }
        
        guard let dictionary = object as? [String: Any],
              let object = dictionary[keyPath: KeyPath(localKeyPath)] else {
            // Normal, on cherche dans le mauvais objet.
            return [String: Any]()
        }
        
        switch remoteKeyPath.headAndTail {
        case nil:
            return [String: Any]()
            
        case let (_, remainingKeyPath)? where remainingKeyPath.isEmpty:
            let value = toArray ? [object] : object
            return value
            
        case let (_, remainingKeyPath)?:
            let value = try formatValue(object, localKeyPath: localKeyPath, remoteKeyPath: remainingKeyPath.path, toArray: toArray)
            return value
        }
    }
    
    func filterEmptyObjects(_ object: Any) -> Any? {
        if let arrayOfDictionaries = object as? [[String: Any]] {
            return arrayOfDictionaries.compactMap { filterEmptyObjects($0) }
            
        } else if let dictionary = object as? [String: Any] {
            let mapped = dictionary.compactMapValues { filterEmptyObjects($0) }
            return mapped.keys.isEmpty ? nil : mapped
            
        } else if let array = object as? [Any] {
            return array.compactMap { filterEmptyObjects($0) }
        }
        
        return object
    }
}

//
//  JSONDecoder+JsonSchema.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//


import Foundation

extension JSONDecoder {
    
    public func decode<T>(_ type: T.Type = T.self, from data: Data) throws -> T where T: Decodable, T: JsonSchemaExpressible {
        try decode(type, from: data, schema: T.decodingSchema)
    }
    
    public func decode<S, K>(_ type: S.Type = S.self, from data: Data) throws -> S where K: Decodable, K: JsonSchemaExpressible, S: Decodable, S: Sequence, K == S.Element {
        try decode(type, from: data, schema: K.decodingSchema)
    }
}

extension JSONDecoder {
    
    public func decode<S, K>(_ type: S.Type = S.self, from data: Data, schema: JsonSchema<K>) throws -> S where K: Decodable, S: Decodable, S: Sequence, K == S.Element {
        return try deserialize(try buildJSON(from: data, schema: schema))
    }
    
    public func decode<T>(_ type: T.Type = T.self, from data: Data, schema: JsonSchema<T>) throws -> T where T: Decodable {
        var value: Any = try buildJSON(from: data, schema: schema)
        
        // Si notre input est un array, on a reconstitué notre objet au sein d'un array.
        if let arrayOfDictionaries = value as? [Any] {
            switch schema {
            case .object, .array:
                value = arrayOfDictionaries.mergingDictionaries()
            default: break
            }
        }
        
        return try deserialize(value)
    }
}

private extension JSONDecoder {
    
    func deserialize<T>(_ object: Any) throws -> T where T: Decodable {
        do {
            let data = try JSONSerialization.data(withJSONObject: object)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw JsonSchemaError.decoding("\(error)")
        }
    }
    
    func buildJSON<T>(from data: Data, schema: JsonSchema<T>) throws -> Any where T: Decodable {
        var value: Any
        
        do {
            value = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        } catch {
            throw JsonSchemaError.decoding("\(error)")
        }
        
        value = try formatJSON(value, schema: schema) as Any
        
        if let someOptional = value as? SomeOptional, someOptional.isSome() {
            value = someOptional.unwrap()
        }
        
        guard let value = filterEmptyObjects(value) else {
            throw JsonSchemaError.decoding("Le json est vide")
        }
        
        return value
    }
    
    func formatJSON<T>(_ object: Any?, schema: JsonSchema<T>) throws -> Any? where T: Decodable {
        guard let object = object else {
            throw JsonSchemaError.formating("L'objet à décoder ne peut pas être nil.")
        }
        
        var value: Any = object
        
        if let someOptional = value as? SomeOptional, someOptional.isSome() {
            value = someOptional.unwrap()
        }
        
        return switch schema {

        case let .object(key, properties) where key.isEmpty:
            try formatRootObject(object: value, properties: properties)
            
        case let .object(key, properties):
            try formatObject(object: value, key: key, properties: properties)
        
        case let .array(key, properties) where key.isEmpty:
            try formatRootArray(object: value, properties: properties)
        
        case let .array(key, properties):
            try formatArray(object: value, key: key, properties: properties)
            
        case .allProperties:
            try formatAllProperties(object: value)

        case let .property(localKeyPath, remoteKeyPath, toArray):
            try formatProperty(object: value, localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray)
            
        case let .value(localKeyPath, remoteKeyPath, toArray):
            try formatValue(object: value, localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray)
        }
    }
    
    func formatRootObject<T>(object: Any?, properties: [JsonSchema<T>]) throws -> Any? where T: Decodable {
        guard let object = object else {
            return [String: Any]()
        }
        
        return try properties.compactMap { try formatJSON(object, schema: $0) }.flatten()
    }
    
    func formatRootArray<T>(object: Any?, properties: [JsonSchema<T>]) throws -> Any? where T: Decodable {
        guard let object = object else {
            return [String: Any]()
        }
        
        guard let array = object as? [Any] else {
            throw JsonSchemaError.formating("Un noeud .array nécéssite de traiter un tableau.")
        }
        
        return try array.map { a in
            let object = try properties.compactMap { try formatJSON(a, schema: $0) }.mergingDictionaries()
        
            if let array = object as? [Any] {
                return array.flatten().mergingDictionaries()
            }
            
            return object
        }
    }
    
    func formatObject<T>(object: Any?, key: String, properties: [JsonSchema<T>]) throws -> Any? where T: Decodable {
        guard let object = object else {
            return [String: Any]()
        }
        
        if key.isEmpty {
            return try properties.compactMap { try formatJSON(object, schema: $0) }.flatten()
        }
        
        return try properties.compactMap { try formatObject(object: object, key: key, property: $0) }.flatten()
    }
    
    func formatObject<T>(object: Any?, key: String, property: JsonSchema<T>) throws -> Any? where T: Decodable {
        guard let object = object else {
            return [String: Any]()
        }
        
        if let dictionary = object as? [String: Any],
           let value = dictionary[key] {
            return try formatJSON(value, schema: property)
        } else if let array = object as? [Any] {
            return try array.compactMap { try formatJSON($0, schema: property) }
        }
        
        return object
    }
    
    func formatArray<T>(object: Any?, key: String, properties: [JsonSchema<T>]) throws -> Any? where T: Decodable {
        guard let object = object else {
            return [String: Any]()
        }
        
        if let array = object as? [Any] {
            return try formatArrayOfObjects(array: array, key: key, properties: properties)
            
        } else if let dictionary = object as? [String: Any],
                  let array = dictionary[key] as? [Any] {
            return try formatArrayOfObjects(array: array, key: key, properties: properties)
        }
        
        return [String: Any]()
    }
    
    func formatArrayOfObjects<T>(array: [Any], key: String, properties: [JsonSchema<T>]) throws -> Any? where T: Decodable {
        let result = try array.compactMap { element in
            var object = try formatObject(object: element, key: "", properties: properties)
            
            if let array = object as? [Any] {
                object = array.flatten().mergingDictionaries()
            }
            return object
        }
        return result
    }
    
    func formatAllProperties(object: Any?) throws -> Any {
        guard let object = object else {
            return [String: Any]()
        }
        
        guard let dictionary = object as? [String: Any] else {
            return object
        }
        
        return dictionary
    }
    
    func formatProperty(object: Any?, localKeyPath: String, remoteKeyPath: String, toArray: Bool) throws -> Any {
        guard let object = object else {
            return [String: Any]()
        }
        
        if let array = object as? [Any] {
            return try array.map { try formatProperty(object: $0, localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray) }.mergingDictionaries()
        } else if let dictionary = object as? [String: Any] {
            return try formatKeyPath(object: dictionary[keyPath: KeyPath(remoteKeyPath)], localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray)
        }
        
        return try formatKeyPath(object: object, localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray)
    }
    
    func formatValue(object: Any?, localKeyPath: String, remoteKeyPath: String, toArray: Bool) throws -> Any {
        guard let object = object else {
            return [String: Any]()
        }
        
        if let array = object as? [Any] {
            return try array.map { try formatValue(object: $0, localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray) }.mergingDictionaries()
            
        } else if let dictionary = object as? [String: Any] {
            return try formatValue(object: dictionary[keyPath: KeyPath(remoteKeyPath)], localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray)
        } 
        
        return try formatKeyPath(object: object, localKeyPath: localKeyPath, remoteKeyPath: remoteKeyPath, toArray: toArray)
    }
    
    func formatKeyPath(object: Any, localKeyPath: String, remoteKeyPath: String, toArray: Bool) throws -> Any {
        switch localKeyPath.headAndTail {
        case nil:
            return [String: Any]()
            
        case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
            return [head: toArray ? [object] : object]
            
        case let (head, remainingKeyPath)?:
            return [head: try formatKeyPath(object: object, localKeyPath: remainingKeyPath.path, remoteKeyPath: remoteKeyPath, toArray: toArray)]
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

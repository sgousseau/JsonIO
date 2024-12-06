public extension JsonSchema {
    
    static func object<K>(_ key: K,
                          _ properties: JsonSchema<T>...) -> JsonSchema<T> where T: JsonSchemaExpressible, T.SchemaKey == K, K: JsonSchemaKey {
        .object(key: key.stringValue, properties: properties)
    }
    
    static func object<K>(key: K? = nil,
                          _ properties: JsonSchema<T>...) -> JsonSchema<T> where T: JsonSchemaExpressible, T.SchemaKey == K, K: JsonSchemaKey {
        .object(key: key?.stringValue ?? "", properties: properties)
    }
    
    static func object(key: String? = nil,
                       _ properties: [JsonSchema<T>]) -> JsonSchema<T> {
        .object(key: key ?? "", properties: properties)
    }
}

public extension JsonSchema {
    
    static func array<K>(_ key: K,
                         _ properties: JsonSchema<T>...) -> JsonSchema<T> where T: JsonSchemaExpressible, T.SchemaKey == K, K: JsonSchemaKey  {
        .array(key: key.stringValue, properties: properties)
    }
    
    static func array<K>(key: K? = nil,
                         _ properties: JsonSchema<T>...) -> JsonSchema<T> where T: JsonSchemaExpressible, T.SchemaKey == K, K: JsonSchemaKey  {
        .array(key: key?.stringValue ?? "", properties: properties)
    }
    
    static func array(key: String? = nil,
                      _ properties: [JsonSchema<T>]) -> JsonSchema<T> {
        .array(key: key ?? "", properties: properties)
    }
}

public extension JsonSchema {
    
    static func property<K>(_ key: K,
                            toArray: Bool = false) -> JsonSchema<T> where T: JsonSchemaExpressible, T.SchemaKey == K, K: JsonSchemaKey  {
        .property(localKeyPath: key.stringValue,
                  remoteKeyPath: key.stringValue,
                  toArray: toArray)
    }
    
    static func property<K>(localKey: K? = nil,
                            remoteKey: K? = nil,
                            toArray: Bool = false) -> JsonSchema<T> where T: JsonSchemaExpressible, T.SchemaKey == K, K: JsonSchemaKey {
        .property(localKeyPath: localKey?.stringValue ?? "",
                  remoteKeyPath: remoteKey?.stringValue ?? localKey?.stringValue ?? "",
                  toArray: toArray)
    }
    
    static func property(localKeyPath: String,
                         remoteKeyPath: String? = nil,
                         toArray: Bool = false) -> JsonSchema<T> {
        .property(localKeyPath: localKeyPath,
                  remoteKeyPath: remoteKeyPath ?? localKeyPath,
                  toArray: toArray)
    }
    
    static func property(keyPath: String,
                         toArray: Bool = false) -> JsonSchema<T> {
        .property(localKeyPath: keyPath,
                  remoteKeyPath: keyPath,
                  toArray: toArray)
    }
}

public extension JsonSchema {
    
    static func valueAt<K>(_ key: K,
                           toArray: Bool = false) -> JsonSchema<T> where T: JsonSchemaExpressible, T.SchemaKey == K, K: JsonSchemaKey  {
        .value(localKeyPath: key.stringValue,
               remoteKeyPath: key.stringValue,
               toArray: toArray)
    }
    
    static func valueAt<K>(localKey: K? = nil,
                           remoteKey: K? = nil,
                           toArray: Bool = false) -> JsonSchema<T> where T: JsonSchemaExpressible, T.SchemaKey == K, K: JsonSchemaKey {
        .value(localKeyPath: localKey?.stringValue ?? "",
               remoteKeyPath: remoteKey?.stringValue ?? localKey?.stringValue ?? "",
               toArray: toArray)
    }
    
    static func valueAt(localKeyPath: String,
                        remoteKeyPath: String,
                        toArray: Bool = false) -> JsonSchema<T> {
        .value(localKeyPath: localKeyPath,
               remoteKeyPath: remoteKeyPath,
               toArray: toArray)
    }
    
    static func valueAt(keyPath: String,
                        toArray: Bool = false) -> JsonSchema<T> {
        .value(localKeyPath: keyPath,
               remoteKeyPath: keyPath,
               toArray: toArray)
    }
}


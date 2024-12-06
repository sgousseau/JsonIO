//
//  JsonSchema.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//


public indirect enum JsonSchema<T> {
    
    // {...} ou key = {...}
    case object(key: String, properties: [JsonSchema<T>])
    
    // [...] ou key = [...]
    case array(key: String, properties: [JsonSchema<T>])
    
    // Représente toutes les propriétés l'objet à coder/décoder
    case allProperties
    
    // Représente une propriété de l'objet à coder/décoder (key = ...)
    case property(localKeyPath: String, remoteKeyPath: String, toArray: Bool)
    
    // Représente une valeur de l'objet à coder/décoder (...)
    case value(localKeyPath: String, remoteKeyPath: String, toArray: Bool)
}

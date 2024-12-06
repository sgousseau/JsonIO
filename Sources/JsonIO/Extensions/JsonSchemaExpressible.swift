//
//  JsonSchemaExpressible.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//


public protocol JsonSchemaExpressible {
    static var encodingSchema: JsonSchema<Self> { get }
    static var decodingSchema: JsonSchema<Self> { get }
    associatedtype SchemaKey: JsonSchemaKey
}

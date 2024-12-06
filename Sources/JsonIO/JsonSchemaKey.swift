//
//  JsonSchemaKey.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//


@dynamicMemberLookup
public protocol JsonSchemaKey: RawRepresentable, CodingKey {}

extension JsonSchemaKey where RawValue == String {
    
    public var stringValue: String { rawValue }
    
    subscript(dynamicMember member: String) -> Self? {
        return Self(rawValue: stringValue + "." + member)
    }
}

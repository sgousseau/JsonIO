//
//  JsonSchemaError.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//


import Foundation

public enum JsonSchemaError: Error {
    case encoding(String)
    case decoding(String)
    case formating(String)
}

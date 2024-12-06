//
//  Array+MergingDictionaries.swift
//  JsonIO
//
//  Created by Sébastien Gousseau on 06/12/2024.
//

import Foundation

extension Array where Element == Any {
    
    func flatten() -> [Any] {
        var result = [Any]()
        forEach { (element) -> Void in
            
            if let element = element as? [Any] {
                result.append(contentsOf: element.flatten())
            } else {
                result.append(element)
            }
        }
        return result
    }
    
    public func filterNil() -> Self {
        filter {
            if let optional = $0 as? SomeOptional {
                return optional.isSome()
            }
            return true
        }
        .map {
            if let optional = $0 as? SomeOptional {
                return optional.unwrap()
            }
            return $0
        }
    }
    
    public func mergingDictionaries() -> Any {
        if let arrayOfArray = self as? [[Any]] {
            return arrayOfArray.map { $0.mergingDictionaries() }
            
        } else if let firstElement = first,
                  firstElement is [String: Any] {
            
            return reduce([String: Any]()) { result, element in
                
                var value = [String: Any]()
                
                // Si l'élément n'est pas un dictionaire mais un tableau, on part de sa composition en dictionnaire.
                if let array = element as? [Any], let dictionary = array.mergingDictionaries() as? [String: Any] {
                    value = dictionary
                } else if let dictionary = element as? [String: Any] {
                    value = dictionary
                }
                
                return result.merging(value) { valA, valB in
                    
                    // On merge les array à l'intérieur des dictionnaires.
                    if let dictA = valA as? [String: Any], let dictB = valB as? [String: Any] {
                        return ([dictA, dictB] as [Any]).mergingDictionaries()
                    }
                    
                    // On merge les arrays / objets any (potentiellement null).
                    if let arrayA = valA as? [Any], let arrayB = valB as? [Any] {
                        return arrayA + arrayB
                    } else if let arrayA = valA as? [Any] {
                        return arrayA + [valB]
                    } else if let arrayB = valB as? [Any] {
                        return [valA] + arrayB
                    } else {
                        return valA
                    }
                }
            }
        }
        
        // Array de primitives
        return self
    }
}

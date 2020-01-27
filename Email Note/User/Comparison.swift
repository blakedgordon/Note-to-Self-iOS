//
//  Comparison.swift
//  Email Note
//
//  Created by Blake Gordon on 1/27/20.
//  Copyright © 2020 Blake Gordon. All rights reserved.
//

import Foundation

/// Compare strings and arrays of strings with case insensitive strings
class Comparison {
    /// Determines if a string is contained in an array while ignoring casing when comparing strings
    /// - Parameters:
    ///   - string: String to determine if it is contained in the Array
    ///   - array: Array of strings that could contain the string
    static func containsCaseInsensitive(_ string: String, _ array: [String]) -> Bool {
        for a in array {
            if a.lowercased() == string.lowercased() {
                return true
            }
        }
        return false
    }
    
    /// Determine if array1 is a subset of array2 while ignoring the capitalizations of the strings
    /// - Parameters:
    ///   - array1: Array of strings to see if it is a subset of array2
    ///   - array2: Array of strings that could contain a subset of array1
    static func isSubsetCaseInsensitive(_ array1: Set<String>, _ array2: Set<String>) -> Bool {
        // Put arrays of strings into sets with each string as all lowercased
        var set1 = Set<String>()
        for s in array1 {
            set1.insert(s.lowercased())
        }
        var set2 = Set<String>()
        for s in array2 {
            set2.insert(s.lowercased())
        }
        
        return set1.isSubset(of: set2)
    }
}

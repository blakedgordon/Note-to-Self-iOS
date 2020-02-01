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
        let lowercaseArray = array.map { $0.lowercased() }
        return lowercaseArray.contains(string.lowercased())
    }
    
    /// Determine if arrayA is a subset of arrayB while ignoring the capitalizations of the strings
    /// - Parameters:
    ///   - arrayA: Array of strings to see if it is a subset of arrayB
    ///   - arrayB: Array of strings that could contain a subset of arrayA
    static func isSubsetCaseInsensitive(_ arrayA: [String], _ arrayB: [String]) -> Bool {
        // Put arrays of strings into sets with each string as all lowercased
        let setA = Set(arrayA.map({ $0.lowercased() }))
        let setB = Set(arrayB.map({ $0.lowercased() }))
        
        return setA.isSubset(of: setB)
    }
}

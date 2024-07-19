//
//  MetalFunction.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Foundation
import Metal


public final class MetalFunction: Hashable, MetalArgumentable {
    
    let name: String
    
    let constants: [(value: UnsafeRawPointer, type: MTLDataType, hash: Int)]
    
    let bundle: Bundle
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(bundle)
        for constant in constants {
            hasher.combine(constant.hash)
        }
    }
    
    public consuming func constant(_ value: some Hashable, type: MTLDataType) -> MetalFunction {
        let hash = value.hashValue
        var value = value
        
        return self.constant(&value, type: type, hash: hash)
    }
    
    private consuming func constant(_ value: UnsafeRawPointer, type: MTLDataType, hash: Int) -> MetalFunction {
        MetalFunction(name: self.name, constants: self.constants + [(value, type, hash)], bundle: self.bundle)
    }
    
    internal func makeFunction(library: MTLLibrary) throws -> MTLFunction {
        if let function = Cache.shared.functions[self] {
            return function
        }
        
        let function: (any MTLFunction)?
        if constants.isEmpty {
            function = library.makeFunction(name: name)
        } else {
            let constants = MTLFunctionConstantValues()
            for (index, constant) in self.constants.enumerated() {
                constants.setConstantValue(constant.value, type: constant.type, index: index)
            }
            function = library.makeFunction(name: name)
        }
        
        guard let function else { throw Error.cannotCreateFunction(name: self.name) }
        
        function.label = "Function<\(self.name)>(constants: \(self.constants))"
        Cache.shared.functions[self] = function
        
        return function
    }
    
    
    private init(name: String, constants: [(value: UnsafeRawPointer, type: MTLDataType, hash: Int)], bundle: Bundle) {
        self.name = name
        self.constants = constants
        self.bundle = bundle
    }
    
    public convenience init(name: String, bundle: Bundle) {
        self.init(name: name, constants: [], bundle: bundle)
    }
    
    public static func == (_ lhs: MetalFunction, _ rhs: MetalFunction) -> Bool {
        guard lhs.name == rhs.name && lhs.constants.count == rhs.constants.count else { return false }
        for (lhs, rhs) in zip(lhs.constants, rhs.constants) {
            guard lhs.hash == rhs.hash else { return false }
        }
        return true
    }
    
    
    public enum Error: LocalizedError, CustomStringConvertible {
        case cannotCreateFunction(name: String)
        
        public var errorDescription: String? { "MetalFunction Error" }
        
        public var failureReason: String? {
            switch self {
            case let .cannotCreateFunction(name):
                "Failed to create function named \"\(name)\", please check spelling and the bundle it is located."
            }
        }
        
        public var description: String {
            self.errorDescription! + ": " + self.failureReason!
        }
    }
    
    @inlinable
    public var arguments: [MetalArgumentFunction.Argument] {
        []
    }
    
    @inlinable
    public var function: MetalFunction {
        self
    }
    
}

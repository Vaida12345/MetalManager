//
//  MetalFunction.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Foundation
@preconcurrency
import Metal


/// The bridge to a Metal function.
///
/// - Important: You cannot reuse a function, due to the current design. Doing so would read from deallocated buffers.
public final class MetalFunction: Hashable, MetalFunctionProtocol, @unchecked Sendable {
    
    let name: String
    
    let constants: [(value: UnsafeRawPointer, type: MTLDataType, hash: Int)]
    
    let bundle: Bundle
    
    
    @inlinable
    public func _get_encoder() -> MetalCommandEncoder? {
        nil
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(bundle)
        for constant in constants {
            hasher.combine(constant.hash)
        }
    }
    
    public consuming func constant<T>(_ value: T, type: MTLDataType) -> MetalFunction where T: Hashable {
        let hash = value.hashValue
        let buffer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        buffer.initialize(to: value)
        
        return MetalFunction(name: self.name, constants: self.constants + [(UnsafeRawPointer(buffer), type, hash)], bundle: self.bundle)
    }
    
    internal func makeFunction(library: MTLLibrary) async throws -> MTLFunction {
        if let function = await Cache.shared.function(for: self) {
            return function
        }
        
        let function: (any MTLFunction)?
        if constants.isEmpty {
            function = library.makeFunction(name: name)
        } else {
            let constants = MTLFunctionConstantValues()
            for (index, constant) in self.constants.enumerated() {
                constants.setConstantValue(constant.value, type: constant.type, index: index)
                constant.value.deallocate()
            }
            function = library.makeFunction(name: name)
        }
        
        guard let function else { throw Error.cannotCreateFunction(name: self.name) }
        
        function.label = "Function<\(self.name)>(constants: \(self.constants))"
        await Cache.shared.set(function: function, key: self)
        
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
    public var _function: MetalFunction {
        self
    }
    
}

//
//  MetalManager.swift
//  The Support Module
//
//  Created by Vaida on 8/1/22.
//  Copyright © 2019 - 2023 Vaida. All rights reserved.
//


#if !os(watchOS)
import CoreML


/// A manager for `Metal` Calculation.
///
/// **Example**
///
/// Performs GPU calculation of the metal file called *calculation*.
///
/// ```swift
/// let manager = try MetalManager(name: "calculation")
///
/// try manager.setBuffer(input)
/// let buffer = try manager.setEmptyBuffer(count: input.count, type: Float.self)
/// try manager.perform(gridSize: MTLSize(width: input.count, height: 1, depth: 1))
///
/// return buffer.contents()
/// ```
///
/// - Important: **Do not** reuse a manager. A metal function is cashed automatically.
///
/// > Experiment:
/// >
/// > - In a benchmark of adding two `Double`s, `vDSP.add` significantly outperformed `Metal`.
/// >
/// > - Any function defined in `Accelerate` significantly outperforms `Metal`.
public final class MetalManager {
    
    /// The `MTLDevice` used for calculation.
    ///
    /// - Note: The default value is `MTLCreateSystemDefaultDevice`.
    private var device: MTLDevice
    
    /// The library for loading the `Metal` function.
    ///
    /// - Note: The default value is `device.makeDefaultLibrary()`.
    private var library: MTLLibrary
    
    /// The constants which severs to pass the arguments at the top of the .metal file.
    ///
    /// - Note: You will need to modify this value to pass the constants.
    ///
    /// **Example**
    /// ```swift
    /// manager.constants.setConstantValue(&intA, type: MTLDataType.int, index: 0)
    /// ```
    private var constants: MTLFunctionConstantValues
    
    /// Defines the size which can be calculated in a batch. the three arguments represent the x, y, z dimensions.
    ///
    /// - Note: The default value is calculated by the `gridSize`.
    public var threadsPerThreadGroup: MTLSize? = nil
    
    /// The name for the `Metal` function.
    private let functionName: String
    
    private var metalFunction: MTLFunction?
    private var pipelineState: MTLComputePipelineState?
    private var commandQueue: MTLCommandQueue?
    private var commandBuffer: MTLCommandBuffer?
    private var commandEncoder: MTLComputeCommandEncoder?
    
    private var currentConstantIndex = 0
    private var currentArrayIndex = 0
    
    
    /// Initialize a `Metal` function with its name.
    ///
    /// Please specify `bundle` as `.bundle` when defining in swift package. The bundle needs to be included when distributing a command line tool.
    ///
    /// - Parameters:
    ///   - name: The name of the metal function, as defined in the `.metal` file.
    ///   - bundle: The bundle where the given `.metal` file is located.
    public init(name: String, fileWithin bundle: Bundle = .main) throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw Error.cannotCreateMetalDevice }
#if os(iOS)
        guard device.supportsFeatureSet(.iOS_GPUFamily4_v1) else { throw Error.hardwareNotSupported }
#endif
        self.device = device
        
        let library = try device.makeDefaultLibrary(bundle: bundle)
        self.library = library
        
        self.functionName = name
        self.constants = MTLFunctionConstantValues()
    }
    
    /// Sets a value for a function constant.
    ///
    /// - Important: This method must be called in the same order as the constants.
    ///
    /// - Precondition: The index of constants in the `.metal` file must start with `0`.
    ///
    /// - Parameters:
    ///   - value: A pointer to the constant value.
    ///   - type: The data type of the function constant.
    public func setConstant(_ value: UnsafeRawPointer, type: MTLDataType) {
        self.constants.setConstantValue(value, type: type, index: currentConstantIndex)
        currentConstantIndex += 1
    }
    
    /// Sets a value for a function constant.
    ///
    /// - Important: This method must be called in the same order as the constants.
    ///
    /// - Parameters:
    ///   - value: A pointer to the constant value.
    public func setConstant(_ value: Int) {
        var _value = value
        self.constants.setConstantValue(&_value, type: .int, index: currentConstantIndex)
        currentConstantIndex += 1
    }
    
    /// Sets a value for a function constant.
    ///
    /// - Important: This method must be called in the same order as the constants.
    ///
    /// - Parameters:
    ///   - value: A pointer to the constant value.
    public func setConstant(_ value: Float) {
        var _value = value
        self.constants.setConstantValue(&_value, type: .float, index: currentConstantIndex)
        currentConstantIndex += 1
    }
    
    /// Submits the constants and make command buffers.
    ///
    /// - Important: This method must be called after passing all the constants and before passing any array.
    ///
    /// - Important: You need to call this function even if no constants were passed.
    private func submitConstants() throws {
        
        // Call the metal function. The name is the function name.
        self.metalFunction = try library.makeFunction(name: functionName, constantValues: constants)
        
        // creates the pipe would stores the calculation
        self.pipelineState = try device.makeComputePipelineState(function: self.metalFunction!)
        
        // generate the buffers where the argument is stored in memory.
        guard let commandQueue = device.makeCommandQueue() else { throw Error.cannotCreateMetalCommandQueue }
        self.commandQueue = commandQueue
        
        guard let commandBuffer = self.commandQueue!.makeCommandBuffer() else { throw Error.cannotCreateMetalCommandBuffer }
        self.commandBuffer = commandBuffer
        
        guard let commandEncoder = self.commandBuffer!.makeComputeCommandEncoder() else { throw Error.cannotCreateMetalCommandEncoder }
        self.commandEncoder = commandEncoder
        self.commandEncoder!.setComputePipelineState(self.pipelineState!)
    }
    
    
    /// Sets a buffer for the compute function.
    ///
    /// Multiple input buffers can be set.
    ///
    /// - Important: This method must be called in the same order as the arguments.
    ///
    /// - Note: The result buffer is managed by the Metal Framework.
    ///
    /// - Parameters:
    ///   - input: The input array.
    ///
    /// - Returns: The encoded buffer, can be retained to obtain results.
    @discardableResult
    public func setBuffer<Element>(_ input: Array<Element>) throws -> MTLBuffer {
        if commandBuffer == nil { try self.submitConstants() }
        
        guard let buffer = input.withUnsafeBufferPointer({ ptr in
            self.device.makeBuffer(bytes: ptr.baseAddress!, length: input.count * MemoryLayout<Element>.size, options: .storageModeShared)
        }) else {
            throw Error.cannotCreateMetalCommandBuffer
        }
        
        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
        currentArrayIndex += 1
        
        return buffer
    }
    
    /// Sets a buffer for the compute function.
    ///
    /// Multiple input buffers can be set.
    ///
    /// - Important: This method must be called in the same order as the arguments.
    ///
    /// - Note: The input buffer is copied, and must be deallocated manually later. The result buffer is managed by the Metal Framework.
    ///
    /// - Parameters:
    ///   - input: A pointer to the constant value.
    ///   - length: The number of elements in this buffer.
    ///
    /// - Returns: The encoded buffer, can be retained to obtain results.
    @discardableResult
    public func setBuffer<Element>(_ input: UnsafeMutablePointer<Element>, length: Int) throws -> MTLBuffer {
        if commandBuffer == nil { try self.submitConstants() }
        
        guard let buffer = self.device.makeBuffer(bytes: input, length: length * MemoryLayout<Element>.size, options: .storageModeShared) else {
            throw Error.cannotCreateMetalCommandBuffer
        }
        
        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
        currentArrayIndex += 1
        return buffer
    }
    
    /// Sets a buffer for the compute function.
    ///
    /// Multiple input buffers can be set.
    ///
    /// - Important: This method must be called in the same order as the arguments.
    ///
    /// - Note: The input buffer is copied, and must be deallocated manually later. The result buffer is managed by the Metal Framework.
    ///
    /// - Parameters:
    ///   - input: A pointer to the constant value.
    ///
    /// - Returns: The encoded buffer, can be retained to obtain results.
    @discardableResult
    @inline(__always)
    public func setBuffer<Element>(_ input: UnsafeMutableBufferPointer<Element>) throws -> MTLBuffer {
        try self.setBuffer(input.baseAddress!, length: input.count)
    }
    
    /// Sets the empty buffer for the compute function.
    ///
    /// - Note: The result buffer is managed by the Metal Framework.
    ///
    /// - Parameters:
    ///   - count: The number of elements in the output buffer.
    ///   - type: The type of such buffer.
    public func setEmptyBuffer<Element>(count: Int, type: Element.Type) throws -> MTLBuffer {
        if commandBuffer == nil { try self.submitConstants() }
        
        guard let buffer = self.device.makeBuffer(length: count * MemoryLayout<Element>.size, options: .storageModeShared) else {
            throw Error.cannotCreateMetalCommandBuffer
        }
        
        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
        currentArrayIndex += 1
        return buffer
    }
    
    /// Runs the function.
    ///
    /// - Parameters:
    ///   - gridSize: Sets the size of the `thread_position_in_grid` in .metal. the three arguments represent the x, y, z dimensions.
    public func perform(gridSize: MTLSize) throws {
        
        guard let pipelineState, let commandBuffer, let commandEncoder else { fatalError("Make sure called `submitConstants` first.") }
        
        if gridSize.height == 1 && gridSize.depth == 1 {
            commandEncoder.dispatchThreads(gridSize,
                                           threadsPerThreadgroup: MTLSize(width: pipelineState.maxTotalThreadsPerThreadgroup,
                                                                          height: 0,
                                                                          depth: 0))
        } else if let threadsPerThreadGroup = threadsPerThreadGroup {
            commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadGroup)
        } else {
            let normalize = { (_ input: Int) -> Int in
                if input == 0 {
                    return 1
                } else {
                    return input
                }
            }
            
            let maxBatchSize = Double(pipelineState.maxTotalThreadsPerThreadgroup)
            let factor = pow(maxBatchSize / Double(normalize(gridSize.width) * normalize(gridSize.height) * normalize(gridSize.depth)), 1 / 3)
            var preSize = [Double(gridSize.width) * factor, Double(gridSize.height) * factor, Double(gridSize.depth) * factor]
            
            if preSize[0] < 1 { preSize[0] = 1 }
            if preSize[1] < 1 { preSize[1] = 1 }
            if preSize[2] < 1 { preSize[2] = 1 }
            
            if preSize[0] == 1 && preSize[1] == 1 {
                preSize[2] = maxBatchSize
            } else if preSize[0] == 1 && preSize[2] == 1 {
                preSize[1] = maxBatchSize
            } else if preSize[1] == 1 && preSize[2] == 1 {
                preSize[0] = maxBatchSize
            } else if preSize[0] == 1 {
                let factor = sqrt(maxBatchSize / (Double(normalize(gridSize.height) * normalize(gridSize.depth))))
                preSize[1] = Double(gridSize.height) * factor
                preSize[2] = Double(gridSize.depth) * factor
            } else if preSize[1] == 1 {
                let factor = sqrt(maxBatchSize / (Double(normalize(gridSize.width) * normalize(gridSize.depth))))
                preSize[0] = Double(gridSize.width) * factor
                preSize[2] = Double(gridSize.depth) * factor
            } else if preSize[2] == 1 {
                let factor = sqrt(maxBatchSize / (Double(normalize(gridSize.width) * normalize(gridSize.height))))
                preSize[0] = Double(gridSize.width) * factor
                preSize[1] = Double(gridSize.height) * factor
            }
            
            commandEncoder.dispatchThreads(gridSize, 
                                           threadsPerThreadgroup: MTLSize(width: min(Int(preSize[0]), gridSize.width),
                                                                          height: min(Int(preSize[1]), gridSize.height),
                                                                          depth: min(Int(preSize[2]), gridSize.depth)))
        }
        
        // Run the metal.
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    private enum Error: LocalizedError {
        
        case cannotCreateMetalDevice
        case cannotCreateMetalLibrary
        case cannotCreateMetalCommandQueue
        case cannotCreateMetalCommandBuffer
        case cannotCreateMetalCommandEncoder
        case invalidGridSize
        case hardwareNotSupported
        
        var errorDescription: String? { "Metal Error" }
        
        var failureReason: String? {
            switch self {
            case .cannotCreateMetalDevice:
                return "Cannot create metal device"
            case .cannotCreateMetalLibrary:
                return "Cannot create metal library"
            case .cannotCreateMetalCommandQueue:
                return "Cannot create metal command queue"
            case .cannotCreateMetalCommandBuffer:
                return "Cannot create metal command buffer"
            case .cannotCreateMetalCommandEncoder:
                return "Cannot create metal command encoder"
            case .invalidGridSize:
                return "Invalid metal grid size"
            case .hardwareNotSupported:
                return "The hardware running this program is too old to support the feature required"
            }
        }
    }
    
}
#endif

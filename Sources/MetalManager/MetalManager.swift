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
/// try manager.submitConstants()
///
/// try manager.setInputBuffer(input)
/// try manager.setOutputBuffer(count: input.count)
/// manager.setGridSize(width: input.count)
///
/// try manager.perform()
/// ```
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
    
    /// The size of the `thread_position_in_grid` in .metal. the three arguments represent the x, y, z dimensions.
    private var gridSize: MTLSize?
    
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
    
    private var outputArrayCount = 0
    
    
    /// Initialize a `Metal` function with its name.
    ///
    /// - Parameters:
    ///   - name: The name of the metal function, as defined in the `.metal` file.
    ///   - bundle: The bundle where the given `.metal` file is located.
    public init(name: String, fileWithin bundle: Bundle = .main) throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw Error.cannotCreateMetalDevice }
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
    
    /// Submits the constants and make command buffers.
    ///
    /// - Important: This method must be called after passing all the constants and before passing any array.
    ///
    /// - Important: You need to call this function even if no constants were passed.
    public func submitConstants() throws {
        
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
    /// - Parameters:
    ///   - input: The input array.
    ///
    /// - Returns: The encoded buffer, can be retained to obtain results.
    @discardableResult
    public func setBuffer<Element>(_ input: Array<Element>) throws -> MTLBuffer {
        precondition(commandEncoder != nil, "Call `submitConstants` first")
        
        guard let buffer = self.device.makeBuffer(bytes: input, length: input.count * MemoryLayout<Element>.size, options: .storageModeShared) else {
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
    /// - Parameters:
    ///   - input: A pointer to the constant value.
    ///   - length: The number of elements in this buffer.
    ///
    /// - Returns: The encoded buffer, can be retained to obtain results.
    @discardableResult
    public func setBuffer<Element>(_ input: UnsafeMutablePointer<Element>, length: Int) throws -> MTLBuffer {
        precondition(commandEncoder != nil, "Call `submitConstants` first")
        
        guard let buffer = self.device.makeBuffer(bytes: input, length: length * MemoryLayout<Element>.size, options: .storageModeShared) else {
            throw Error.cannotCreateMetalCommandBuffer
        }
        
        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
        currentArrayIndex += 1
        return buffer
    }
    
    /// Sets the empty buffer for the compute function.
    ///
    /// - Parameters:
    ///   - count: The number of elements in the output buffer.
    public func setEmptyBuffer<Element>(count: Int, type: Element.Type) throws -> MTLBuffer {
        guard let buffer = self.device.makeBuffer(length: count * MemoryLayout<Element>.size, options: .storageModeShared) else {
            throw Error.cannotCreateMetalCommandBuffer
        }
        
        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
        currentArrayIndex += 1
        return buffer
    }
    
    /// Sets the size of the `thread_position_in_grid` in .metal. the three arguments represent the x, y, z dimensions.
    ///
    /// - Parameters:
    ///   - width: The width of the volume.
    ///   - height: The height of the volume. Set to 1 if the object only has one dimension.
    ///   - depth: The depth of the volume. Set to 1 if the object has one or two dimensions.
    public func setGridSize(width: Int, height: Int = 1, depth: Int = 1) {
        self.gridSize = MTLSize(width: width, height: height, depth: depth)
    }
    
    
    /// Runs the function.
    public func perform() throws {
        
        guard let gridSize else { throw Error.invalidGridSize }
        
        guard let pipelineState, let commandBuffer, let commandEncoder else {
            fatalError("Make sure called `submitConstants` first.")
        }
        
        if let threadsPerThreadGroup = threadsPerThreadGroup {
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
            }
        }
    }
    
}
#endif

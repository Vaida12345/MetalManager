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
    
    /// The sets of command associated with this metal manager.
    private let commandBuffer: MTLCommandBuffer
    
    private let pipelineState: MTLComputePipelineState
    
    private let commandEncoder: MTLComputeCommandEncoder
    
    
    /// Initialize a `Metal` function with its name.
    ///
    /// Please specify `bundle` as `.bundle` when defining in swift package. The bundle needs to be included when distributing a command line tool.
    ///
    /// - Parameters:
    ///   - function: The name of the metal function, as defined in the `.metal` file.
    ///   - bundle: The bundle where the given `.metal` file is located.
    public init(function: MetalArgumentFunction, at bundle: Bundle) throws {
        let device = MetalManager.Configuration.shared.computeDevice
        
#if os(iOS)
        guard device.supportsFeatureSet(.iOS_GPUFamily4_v1) else { throw Error.hardwareNotSupported }
#endif
        
        let library: MTLLibrary
        if let _library = Cache.shared.libraries[bundle] {
            library = _library
        } else {
            library = try device.makeDefaultLibrary(bundle: bundle)
            library.label = "MTLLibrary(bundle: \(bundle))"
            
            Cache.shared.libraries[bundle] = library
        }
        
        
        if let pipeLine = Cache.shared.pipelineStates[function._function] {
            self.pipelineState = pipeLine
        } else {
            let metalFunction = try function._function.makeFunction(library: library)
            let pipe = try device.makeComputePipelineState(function: metalFunction)
            Cache.shared.pipelineStates[function._function] = pipe
            self.pipelineState = pipe
        }
        
        guard let commandBuffer = Cache.shared.commandQueue.makeCommandBuffer() else { throw Error.cannotCreateMetalCommandBuffer }
        commandBuffer.label = "CommandBuffer(for: \(function._function.name))"
        self.commandBuffer = commandBuffer
        
        self.commandEncoder = try function.makeCommandEncoder(commandBuffer: commandBuffer, commandState: pipelineState)
    }
    
//    
//    /// Sets a buffer for the compute function.
//    ///
//    /// Multiple input buffers can be set.
//    ///
//    /// - Important: This method must be called in the same order as the arguments.
//    ///
//    /// - Note: The result buffer is managed by the Metal Framework.
//    ///
//    /// - Parameters:
//    ///   - input: The input array.
//    ///
//    /// - Returns: The encoded buffer, can be retained to obtain results.
//    @discardableResult
//    public func setBuffer<Element>(_ input: Array<Element>) throws -> MTLBuffer {
//        if commandBuffer == nil { try self.submitConstants() }
//        
//        guard let buffer = input.withUnsafeBufferPointer({ ptr in
//            self.device.makeBuffer(bytes: ptr.baseAddress!, length: input.count * MemoryLayout<Element>.stride, options: .storageModeShared)
//        }) else {
//            throw Error.cannotCreateMetalCommandBuffer
//        }
//        
//        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
//        currentArrayIndex += 1
//        
//        return buffer
//    }
//    
//    public func setBuffer(_ buffer: any MTLBuffer) throws {
//        if commandBuffer == nil { try self.submitConstants() }
//        
//        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
//        currentArrayIndex += 1
//    }
//    
//    /// Sets a buffer for the compute function.
//    ///
//    /// Multiple input buffers can be set.
//    ///
//    /// - Important: This method must be called in the same order as the arguments.
//    ///
//    /// - Note: The input buffer is copied, and must be deallocated manually later. The result buffer is managed by the Metal Framework.
//    ///
//    /// - Parameters:
//    ///   - input: A pointer to the constant value.
//    ///   - length: The number of elements in this buffer.
//    ///
//    /// - Returns: The encoded buffer, can be retained to obtain results.
//    @discardableResult
//    public func setBuffer<Element>(_ input: UnsafeMutablePointer<Element>, length: Int) throws -> MTLBuffer {
//        if commandBuffer == nil { try self.submitConstants() }
//        
//        guard let buffer = self.device.makeBuffer(bytes: input, length: length * MemoryLayout<Element>.size, options: .storageModeShared) else {
//            throw Error.cannotCreateMetalCommandBuffer
//        }
//        
//        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
//        currentArrayIndex += 1
//        return buffer
//    }
//    
//    /// Sets a buffer for the compute function.
//    ///
//    /// Multiple input buffers can be set.
//    ///
//    /// - Important: This method must be called in the same order as the arguments.
//    ///
//    /// - Note: The input buffer is copied, and must be deallocated manually later. The result buffer is managed by the Metal Framework.
//    ///
//    /// - Important: The input buffer does not reflect the changes to the MTLBuffer.
//    ///
//    /// - Parameters:
//    ///   - input: A pointer to the constant value.
//    ///
//    /// - Returns: The encoded buffer, can be retained to obtain results.
//    @discardableResult
//    @inline(__always)
//    public func setBuffer<Element>(_ input: UnsafeMutableBufferPointer<Element>) throws -> MTLBuffer {
//        try self.setBuffer(input.baseAddress!, length: input.count)
//    }
//    
//    /// Sets the empty buffer, filled with `zero`, for the compute function.
//    ///
//    /// - Note: The result buffer is managed by the Metal Framework.
//    ///
//    /// - Parameters:
//    ///   - count: The number of elements in the output buffer.
//    ///   - type: The type of such buffer.
//    public func setEmptyBuffer<Element>(count: Int, type: Element.Type) throws -> MTLBuffer {
//        if commandBuffer == nil { try self.submitConstants() }
//        
//        guard let buffer = self.device.makeBuffer(length: count * MemoryLayout<Element>.size, options: .storageModeShared) else {
//            throw Error.cannotCreateMetalCommandBuffer
//        }
//        
//        self.commandEncoder!.setBuffer(buffer, offset: 0, index: currentArrayIndex)
//        currentArrayIndex += 1
//        return buffer
//    }
    
    /// Runs the function.
    ///
    /// - Parameters:
    ///   - gridSize: Sets the size of the `thread_position_in_grid` in .metal. the three arguments represent the x, y, z dimensions.
    public func perform(gridSize: MTLSize) throws {
        let supportsNonuniform: Bool
        
        if #available(macOS 10.15, *) {
            if MetalManager.Configuration.shared.computeDevice.supportsFamily(.apple4) {
                supportsNonuniform = true
            } else {
                supportsNonuniform = false
            }
        } else {
            supportsNonuniform = false
        }
        
        
        if gridSize.height == 1 && gridSize.depth == 1 {
            let threadsPerThreadgroup = MTLSize(width: pipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            let threadgroupsPerGrid = MTLSize(width: (gridSize.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                              height: 1,
                                              depth: 1)
            
            if supportsNonuniform {
                commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
            } else {
                commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            }
        } else {
            let threadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)
            let threadgroupsPerGrid = MTLSize(width: (gridSize.width + 15) / 16,
                                              height: (gridSize.height + 15) / 16,
                                              depth: 1)
            
            if supportsNonuniform {
                commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
            } else {
                commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            }
        }
        
        // Run the metal.
        commandEncoder.endEncoding()
        commandBuffer.commit()
        
        let commit_date = Date()
        print("Start to compute")
        commandBuffer.waitUntilCompleted()
        if #available(macOS 10.15, *) {
            print("Actual Compute took \(commit_date.distance(to: Date()))")
        }
    }
    
    /// Runs the function.
    ///
    /// The parameters set the size of the `thread_position_in_grid` in .metal. the three arguments represent the x, y, z dimensions.
    public func perform(width: Int, height: Int = 1, depth: Int = 1) throws {
        try self.perform(gridSize: MTLSize(width: width, height: height, depth: depth))
    }
    
    public enum Error: LocalizedError, CustomStringConvertible {
        
        case cannotCreateMetalDevice
        case cannotCreateMetalLibrary
        case cannotCreateMetalCommandQueue
        case cannotCreateMetalCommandBuffer
        case cannotCreateTextureFromImage
        case cannotCreateMetalCommandEncoder
        case invalidGridSize
        case hardwareNotSupported
        
        public var errorDescription: String? { "Metal Error" }
        
        public var failureReason: String? {
            switch self {
            case .cannotCreateMetalDevice:
                return "Cannot create metal device"
            case .cannotCreateMetalLibrary:
                return "Cannot create metal library"
            case .cannotCreateMetalCommandQueue:
                return "Cannot create metal command queue"
            case .cannotCreateMetalCommandBuffer:
                return "Cannot create metal command buffer. Please check \"commandQueueLength\" in \"MetalManager.Configuration\"."
            case .cannotCreateMetalCommandEncoder:
                return "Cannot create metal command encoder"
            case .invalidGridSize:
                return "Invalid metal grid size"
            case .hardwareNotSupported:
                return "The hardware running this program is too old to support the feature required"
            case .cannotCreateTextureFromImage:
                return "Cannot create a MTLTexture from the given CGImage."
            }
        }
        
        public var description: String {
            self.errorDescription! + ": " + self.failureReason!
        }
    }
    
}
#endif

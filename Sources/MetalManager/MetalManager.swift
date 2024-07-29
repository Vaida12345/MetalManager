//
//  MetalManager.swift
//  The Support Module
//
//  Created by Vaida on 8/1/22.
//  Copyright © 2019 - 2023 Vaida. All rights reserved.
//


#if !os(watchOS)
@preconcurrency import CoreML


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
    public init(function: MetalArgumentFunction) async throws {
        let device = MetalManager.Configuration.shared.computeDevice
        
#if os(iOS)
        guard device.supportsFeatureSet(.iOS_GPUFamily4_v1) else { throw Error.hardwareNotSupported }
#endif
        
        let library: MTLLibrary
        let bundle = function._function.bundle
        if let _library = await Cache.shared.library(for: bundle) {
            library = _library
        } else {
            library = try device.makeDefaultLibrary(bundle: bundle)
            library.label = "MTLLibrary(bundle: \(bundle))"
            
            await Cache.shared.set(library: library, key: bundle)
        }
        
        
        if let pipeLine = await Cache.shared.pipelineState(for: function._function) {
            self.pipelineState = pipeLine
        } else {
            let metalFunction = try await function._function.makeFunction(library: library)
            let pipe = try await device.makeComputePipelineState(function: metalFunction)
            await Cache.shared.set(pipelineState: pipe, key: function._function)
            self.pipelineState = pipe
        }
        
        guard let commandBuffer = await Cache.shared.commandQueue.makeCommandBuffer() else { throw Error.cannotCreateMetalCommandBuffer }
        commandBuffer.label = "CommandBuffer(for: \(function._function.name))"
        self.commandBuffer = commandBuffer
        
        self.commandEncoder = try function.makeCommandEncoder(commandBuffer: commandBuffer, commandState: pipelineState)
    }
    
    nonisolated(unsafe) static var supportsNonUniformGridSize: Bool = {
        if #available(macOS 10.15, *) {
            if MetalManager.Configuration.shared.computeDevice.supportsFamily(.apple4) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }()
    
    /// Runs the function.
    ///
    /// - Parameters:
    ///   - gridSize: Sets the size of the `thread_position_in_grid` in .metal. the three arguments represent the x, y, z dimensions.
    public func perform(gridSize: MTLSize) async throws {
        let supportsNonuniform: Bool = MetalManager.supportsNonUniformGridSize
        
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
    public func perform(width: Int, height: Int = 1, depth: Int = 1) async throws {
        try await self.perform(gridSize: MTLSize(width: width, height: height, depth: depth))
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

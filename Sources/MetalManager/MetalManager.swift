//
//  MetalManager.swift
//  The Support Module
//
//  Created by Vaida on 8/1/22.
//  Copyright © 2019 - 2023 Vaida. All rights reserved.
//

import Foundation


/// A manager for `Metal` Calculation.
public final class MetalManager {
    
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
    
    /// Prepare cache for this app.
    ///
    /// Call this to facilitate faster execution, for example, when launching the app.
    public static func prepareCache() async {
        let _ = Cache.shared.commandQueue
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

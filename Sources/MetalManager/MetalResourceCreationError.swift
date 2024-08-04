//
//  MetalResourceCreationError.swift
//  MetalManager
//
//  Created by Vaida on 7/31/24.
//

import Foundation
import CoreGraphics


/// An error indicating failure of some metal resource creation.
public enum MetalResourceCreationError: LocalizedError, CustomStringConvertible {
    /// Indicates failure of `MTLBuffer` creation.
    case cannotCreateBuffer(source: String)
    case cannotCreateTexture(reason: TextureFailureReason)
    case cannotCreateCGImageFromTexture
    
    
    public var description: String {
        switch self {
        case .cannotCreateBuffer(let source):
            "Failed to create Metal buffer from \(source)"
        case .cannotCreateTexture(let reason):
            "Failed to create Metal texture: \(reason.description)"
        case .cannotCreateCGImageFromTexture:
            "Failed to create CGImage form MTLTexture, the texture data is incompatible."
        }
    }
    
    public var errorDescription: String? {
        self.description
    }
    
    public enum TextureFailureReason: CustomStringConvertible, Sendable {
        case cannotCreateEmptyTexture(width: Int, height: Int)
        case cannotObtainImageData(image: CGImage)
        
        public var description: String {
            switch self {
            case let .cannotCreateEmptyTexture(width, height):
                "Failed to create an empty texture of size (\(width), \(height))."
            case .cannotObtainImageData(let image):
                "Failed to obtain image data from \(image)"
            }
        }
    }
}

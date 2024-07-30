//
//  MetalDependentState.swift
//  CanvasKit
//
//  Created by Vaida on 7/30/24.
//

import Metal


/// A state whose value is dependent on Metal, and may not be synchronized yet.
public final class MetalDependentState<Content> {
    
    private let context: MetalContext
    
    internal var content: any MTLBuffer
    
    
    /// Execute the command buffer stored in the context, ensuring all pending jobs are executed.
    ///
    /// - Important: To maximize efficiency, you should aim to evoke this as few as possible.
    public func synchronize() async throws -> Content {
        try await context.synchronize()
        return content.contents().assumingMemoryBound(to: Content.self).pointee
    }
    
    public init(initialValue: Content, context: MetalContext) {
        var initialValue = initialValue
        self.context = context
        self.content = MetalManager.computeDevice.makeBuffer(bytes: &initialValue, length: MemoryLayout<Content>.size)!
    }
    
}

//
//  MetalDependentState.swift
//  CanvasKit
//
//  Created by Vaida on 7/30/24.
//

import Metal


/// A state whose value is dependent on Metal, and may not be synchronized yet.
///
/// This structure is only designed for the CPU's benefit. For GPU, you could pass such state to `Metal` using ``MetalArgumentFunction/argument(state:)``.
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
    
    /// Creates the state with its initial value.
    ///
    /// - Important: The size of `Content` needs to be less than 4KB.
    public init(initialValue: Content, context: MetalContext) {
        let size = MemoryLayout<Content>.size
        precondition(size < 4096)
        
        self.context = context
        
        let buffer = UnsafeMutablePointer<Content>.allocate(capacity: 1)
        buffer.initialize(to: initialValue)
        self.content = MetalManager.computeDevice.makeBuffer(bytes: buffer, length: size)!
        buffer.deallocate()
    }
    
}

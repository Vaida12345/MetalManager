//
//  MetalDependentState.swift
//  CanvasKit
//
//  Created by Vaida on 7/30/24.
//


/// A state whose value is dependent on Metal, and may not be synchronized yet.
public final class MetalDependentState<Content> {
    
    private let context: MetalContext
    
    internal var content: UnsafeMutablePointer<Content>
    
    
    /// Execute the command buffer stored in the context, ensuring all pending jobs are executed.
    ///
    /// - Important: To maximize efficiency, you should aim to evoke this as few as possible.
    public func synchronize() async throws -> Content {
        try await context.synchronize()
        return content.pointee
    }
    
    public init(initialValue: Content, context: MetalContext) {
        self.context = context
        self.content = .allocate(capacity: 1)
        self.content.initialize(to: initialValue)
    }
    
    deinit {
        self.content.deallocate()
    }
    
}

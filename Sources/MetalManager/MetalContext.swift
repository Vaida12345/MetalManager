//
//  MetalContext.swift
//  CanvasKit
//
//  Created by Vaida on 7/29/24.
//


/// The coordinator of execution.
public actor MetalContext {
    
    var commandBuffer: MetalCommandBuffer
    
    var state: State
    
    
    /// Execute the command buffer when required, ensuring all pending jobs are executed.
    ///
    /// - Important: To maximize efficiency, you should aim to evoke this as few as possible.
    public func synchronize() async throws {
        guard self.state == .pending else { return }
        let buffer = self.commandBuffer
        self.state = .working
        await buffer.perform()
        self.state = .empty
        
        self.commandBuffer = try await MetalCommandBuffer()
    }
    
    public func addJob() async throws -> MetalCommandBuffer {
        self.state = .pending
        return self.commandBuffer
    }
    
    
    public init() async throws {
        self.commandBuffer = try await MetalCommandBuffer()
        self.state = .empty
    }
    
    enum State {
        /// Has pending jobs
        case pending
        /// No pending jobs
        case empty
        /// Working on some jobs.
        case working
    }
    
}

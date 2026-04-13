//
//  MetalContext.swift
//  CanvasKit
//
//  Created by Vaida on 7/29/24.
//

import Foundation


/// The coordinator of execution.
///
/// A context only contains information to perform the functions linked to it. Metal resources and functions are created only when `synchronize()` is called. Hence it is safe to discard any context at any time.
public final actor MetalContext {
    
    var commandBuffer: MetalCommandBuffer
    
    var state: State
    
    var prerequisites: [@Sendable () throws -> Void]
    
    
    /// Execute the command buffer when required, ensuring all pending jobs are executed.
    ///
    /// - Important: To maximize efficiency, you should aim to evoke this as few as possible.
    public func synchronize() async throws {
        if !prerequisites.isEmpty {
            for prerequisite in prerequisites {
                try prerequisite()
            }
            prerequisites.removeAll(keepingCapacity: true)
        }
        
        guard self.state == .pending else { return }
        
        let buffer = self.commandBuffer
        self.state = .working
        try await buffer.perform()
        self.state = .empty
    }
    
    func addJob() -> MetalCommandBuffer {
        self.state = .pending
        return self.commandBuffer
    }
    
    
    public init() {
        self.commandBuffer = MetalCommandBuffer()
        self.state = .empty
        self.prerequisites = []
    }
    
    /// Adds CPU-side prerequisite work that must finish before the next synchronization runs GPU work.
    func addPrerequisite(_ work: @Sendable @escaping () throws -> Void) {
        self.prerequisites.append(work)
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

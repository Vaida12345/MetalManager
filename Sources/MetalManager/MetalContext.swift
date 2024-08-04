//
//  MetalContext.swift
//  CanvasKit
//
//  Created by Vaida on 7/29/24.
//

import Foundation


/// The coordinator of execution.
public final actor MetalContext {
    
    var commandBuffer: MetalCommandBuffer
    
    var state: State
    
    var prerequisites: [() throws -> Void]
    
    
    /// Execute the command buffer when required, ensuring all pending jobs are executed.
    ///
    /// - Important: To maximize efficiency, you should aim to evoke this as few as possible.
    public func synchronize() async throws {
        let date = Date()
        let prev = prerequisites
        if !prerequisites.isEmpty {
            for prerequisite in prerequisites {
                try await prerequisite()
            }
            prerequisites.removeAll()
        }
        print("calc prerequisite of \(prev) took \(date.distance(to: Date()) * 1000)")
        
        guard self.state == .pending else { return }
        
        let buffer = self.commandBuffer
        self.state = .working
        try await buffer.perform()
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
        self.prerequisites = []
    }
    
    func addPrerequisite(_ work: @Sendable @escaping () throws -> Void) {
        print("add work")
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

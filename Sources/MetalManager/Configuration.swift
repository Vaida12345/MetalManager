//
//  Configuration.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Metal
import MetalKit


extension MetalManager {
    
    public struct Configuration {
        
        /// The default compute device for texture / buffer allocation, library creation, computation, and more.
        public lazy var computeDevice = MTLCreateSystemDefaultDevice()!
        
        /// The number of command queues that the main command queue can hold.
        public var commandQueueLength: Int = 8
        
        
        nonisolated(unsafe) public static var shared = Configuration()
        
    }
    
}

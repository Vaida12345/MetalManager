//
//  Utilities.swift
//  MetalManager
//
//  Created by Vaida on 7/31/24.
//

import Metal


func MTLComputeCommandEncoderDispatch(encoder: any MTLComputeCommandEncoder, pipelineState: any MTLComputePipelineState, width: Int, height: Int, depth: Int) {
    // Commit the function & buffers
    let supportsNonuniform: Bool = MetalManager.supportsNonUniformGridSize
    let gridSize = MTLSize(width: width, height: height, depth: depth)
    
    if height == 1 && depth == 1 {
        let threadsPerThreadgroup = MTLSize(width: pipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        let threadgroupsPerGrid = MTLSize(width: (gridSize.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                          height: 1,
                                          depth: 1)
        
        if supportsNonuniform {
            encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
        } else {
            encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }
    } else {
        let size = Int(sqrt(Double(pipelineState.maxTotalThreadsPerThreadgroup)))
        
        let threadsPerThreadgroup = MTLSize(width: size, height: size, depth: 1)
        let threadgroupsPerGrid = MTLSize(width: (width + size - 1) / size,
                                          height: (height + size - 1) / size,
                                          depth: 1)
        
        if supportsNonuniform {
            encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
        } else {
            encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }
    }
}

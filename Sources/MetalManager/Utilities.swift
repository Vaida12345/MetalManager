//
//  Utilities.swift
//  MetalManager
//
//  Created by Vaida on 7/31/24.
//

import Metal


@inline(__always)
private func ceilDivide(_ lhs: Int, _ rhs: Int) -> Int {
    (lhs + rhs - 1) / rhs
}

@inline(__always)
func optimalThreadsPerThreadgroup(for pipelineState: any MTLComputePipelineState, gridSize: MTLSize) -> MTLSize {
    let maxThreads = max(1, pipelineState.maxTotalThreadsPerThreadgroup)
    let executionWidth = max(1, pipelineState.threadExecutionWidth)

    if gridSize.height == 1 && gridSize.depth == 1 {
        var width = min(gridSize.width, maxThreads)
        width = max(executionWidth, (width / executionWidth) * executionWidth)
        width = min(width, maxThreads)
        return MTLSize(width: max(1, width), height: 1, depth: 1)
    }

    let width = min(max(executionWidth, 1), maxThreads)
    let remainingThreads = max(1, maxThreads / width)
    let height = min(max(1, gridSize.height), remainingThreads)
    let depth = min(max(1, gridSize.depth), max(1, remainingThreads / height))

    return MTLSize(width: width, height: height, depth: depth)
}

func MTLComputeCommandEncoderDispatch(encoder: any MTLComputeCommandEncoder, pipelineState: any MTLComputePipelineState, width: Int, height: Int, depth: Int) {
    let supportsNonuniform: Bool = MetalManager.supportsNonUniformGridSize
    let gridSize = MTLSize(width: width, height: height, depth: depth)

    let threadsPerThreadgroup = optimalThreadsPerThreadgroup(for: pipelineState, gridSize: gridSize)
    let threadgroupsPerGrid = MTLSize(
        width: ceilDivide(gridSize.width, threadsPerThreadgroup.width),
        height: ceilDivide(gridSize.height, threadsPerThreadgroup.height),
        depth: ceilDivide(gridSize.depth, threadsPerThreadgroup.depth)
    )

    if supportsNonuniform {
        encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
    } else {
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}

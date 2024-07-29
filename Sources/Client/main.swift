//
//  main.swift
//  MetalManager
//
//  Created by Vaida on 7/29/24.
//

import MetalManager


var array = [1, 2, 3, 4, 5, 6, 7, 8] as [Float]
let buffer = MetalManager.computeDevice.makeBuffer(bytesNoCopy: &array, length: array.count * MemoryLayout<Float>.stride)!

let commandBuffer = try await MetalCommandBuffer()

try await MetalFunction(name: "doubleValues", bundle: .module)
    .argument(buffer: buffer)
    .dispatch(to: commandBuffer, width: array.count)

try await MetalFunction(name: "addConstant", bundle: .module)
    .argument(buffer: buffer)
    .dispatch(to: commandBuffer, width: array.count)

await commandBuffer.perform()

print(array)

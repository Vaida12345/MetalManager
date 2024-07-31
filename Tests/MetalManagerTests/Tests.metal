//
//  advance.metal
//  MetalManager
//
//  Created by Vaida on 7/29/24.
//


#include <metal_stdlib>
using namespace metal;

kernel void doubleValues(device float *data,
                         uint id [[ thread_position_in_grid ]]) {
    data[id] *= 2.0;
}

kernel void addConstant(device float *data,
                        uint id [[ thread_position_in_grid ]]) {
    data[id] += 5.0;
}

kernel void allEqual(device float *data,
                     device bool* result,
                    uint id [[ thread_position_in_grid ]]) {
    if (data[0] != data[id])
        *result = false;
}

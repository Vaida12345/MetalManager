
#include <metal_stdlib>
using namespace metal;

kernel void linear(device float* buffer,
                   uint index [[thread_position_in_grid]])

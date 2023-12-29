
#include <metal_stdlib>
using namespace metal;

constant float alpha [[function_constant(0)]];
constant float beta  [[function_constant(1)]];

kernel void linear(device float* buffer,
                   uint index [[thread_position_in_grid]]) {
    buffer[index] = alpha * buffer[index] + beta;
}

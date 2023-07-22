
#include <metal_stdlib>
using namespace metal;

constant int intA [[function_constant(0)]];
constant int intB [[function_constant(1)]];

kernel void calculation(device const float* input,
                        device float* output,
                        uint index [[thread_position_in_grid]]
                        ) {
    
}

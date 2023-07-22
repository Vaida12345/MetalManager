
#include <metal_stdlib>
using namespace metal;


kernel void calculation(device const float* input,
                        device float* output,
                        uint index [[thread_position_in_grid]]
                        ) {
    
}

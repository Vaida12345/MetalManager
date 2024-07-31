# Running Metal

Prepare and execute a single use metal function.


## Define the function

To use metal, define the function in Metal Shader Language (MSL). To read more about MSL, check out the [official documentation](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf).

This example adds `5` to each element of the array.

```c
#include <metal_stdlib>
using namespace metal;

kernel void addConstant(device float *data,
                        uint id [[ thread_position_in_grid ]]) {
    data[id] += 5.0;
}
```

## The Swift driver

With this function, we can write Swift driver to use it.

Define the input / output array

```swift
var array = [1, 2, 3, 4, 5, 6, 7, 8] as [Float]

// Create a buffer by referencing the IO array.
let buffer = try MetalManager.computeDevice.makeBuffer(bytesNoCopy: &array)
```

Define the function by specifying the `name` field, which is the name of the metal function previously defined. The `bundle` parameter indicates the location of the metal file containing this function, typically designated as `module` when working within a Swift Package, and `main` when developing apps.

The second line specifies the sole argument for the function, the buffer. The third line initiates the execution of the metal function.

```swift
try await MetalFunction(name: "doubleValues", bundle: .module)
    .argument(buffer: buffer)
    .perform(width: array.count)
```

## Next Step

Learn how to reduce overhead by running metal functions in batches [here](<doc:Serialized-Execution>).

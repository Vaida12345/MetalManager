
# Argument Buffers

Use argument buffers to reduce CPU overhead, simplify resource management, and implement GPU-driven pipelines.

## Defining parameters

You typically start by defining the parameters, separated for `metal` and `swift`.

```c
// GenerateBinarizedParameters.metal
struct GenerateBinarizedParameters {
    int neighbor;
    float threshold;
    int classCount;
    int frameCount;
};
```

- Important: The `int` type in `metal` is `Int32` in `swift`.

```swift
// driver.swift
struct GenerateBinarizedParameters {
    let neighbor: Int32
    let threshold: Float32
    let classCount: Int32
    let frameCount: Int32
}
```

## Passing Argument

```c
kernel void generateBinarized(
    device const float* buffer,
    constant GenerateBinarizedParameters& params,
    uint2 index [[thread_position_in_grid]]
) {
    ...
}
```

When the latest `MetalManager`, you could just pass the arguments in the order as they are defined in `metal`.

```swift
let parameters = GenerateBinarizedParameters(
    neighbor: Int32(neighbor), 
    threshold: threshold, 
    classCount: Int32(classCount), 
    frameCount: Int32(frameCount)
)

try await MetalFunction(name: "generateBinarized", bundle: .module)
    .argument(buffer: buffer)
    .argument(bytes: parameters)
    .perform(width: frameCount, height: classCount)
```

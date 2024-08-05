# Advanced Coordination

Minimize synchronization between the CPU and GPU to reduce latency.


## Define the function

Assume we want to check if contents of an non-empty array are all equal to each other using Metal.

```c
kernel void allEqual(device float *data,
                     device bool* result,
                     uint id [[ thread_position_in_grid ]]) {
    if (data[0] != data[id])
        *result = false;
}
```


## The Swift Driver

As before, define the buffer.
```swift
var array = [1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1] as [Float]
let buffer = try MetalManager.computeDevice.makeBuffer(bytesNoCopy: &array)
```

Now, instead of using ``MetalCommandBuffer``, we can use ``MetalContext`` for advanced coordinations.

```swift
let context = MetalContext()
```

For the buffer storing the `result`, we can use ``MetalDependentState``. Such structure would ensure the only way you can access the buffer is *after* it has been synchronized via  ``MetalDependentState/synchronize()``.

```
let result = MetalDependentState(initialValue: true, context: context)
```

Add the job to the context.

```swift
try await MetalFunction(name: "allEqual", bundle: .module)
    .argument(buffer: buffer)
    .argument(state: result)
    .dispatch(to: context, width: array.count)
```

The job is now submitted, and it won't execute until you call either
```swift
try await context.synchronize()
```
Or
```swift
try await result.synchronize()
```

In this way, the `context` would attempt to gather as many functions as possible to run the computations in a single batch.

For the `result`, you can pass it to subsequence metal functions as if it has already been computed via ``MetalArgumentFunction/argument(state:)``, as `context` would ensure these jobs are completed in serial.

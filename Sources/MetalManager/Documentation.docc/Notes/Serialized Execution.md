# Serialized Execution

Use a single command buffer to execute multiple commands (functions)


## Motivation 

In the previous implementation of MetalManager, or with the ``MetalArgumentFunction/perform(width:height:depth:)`` method of ``MetalArgumentFunction``, each function operated on its own command buffer. Consequently, the CPU was required to commit buffers and initiate functions individually for each instance, resulting in substantial overhead.

## Solution

Now with ``MetalCommandBuffer`` and ``MetalArgumentFunction/dispatch(to:width:height:depth:)-6gdmq``, you could commit multiple functions at once.

### Example

You can begin by defining the functions as you normally would.

- Tip: When functions are not specialized, which is recommended, you can define multiple metal functions within the same file.

```c
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

```

Define the buffers

```swift
var array = [1, 2, 3, 4, 5, 6, 7, 8] as [Float]
let buffer = try MetalManager.computeDevice.makeBuffer(bytesNoCopy: &array)
```

Define the command buffer. This buffer is used to hold each individual metal function, and their buffers.

Command buffers created by calling the ``MetalCommandBuffer/init()`` initializer uses the command queue that is shared between all command buffers of the MetalManager package.

```
let commandBuffer = MetalCommandBuffer()
```

Define the functions, sets the buffers and parameters, then dispatch to the command buffer created earlier.

```swift
try await MetalFunction(name: "doubleValues", bundle: .module)
    .argument(buffer: buffer)
    .dispatch(to: commandBuffer, width: array.count)

try await MetalFunction(name: "addConstant", bundle: .module)
    .argument(buffer: buffer)
    .dispatch(to: commandBuffer, width: array.count)
```

Please note that these functions are not executed at this point.

---

Execute and wait for metal completion.

``` swift
try await commandBuffer.perform()
```

## Comparison

The comparison as stated by gpt-4-1106-preview.

| Aspect                    | Single `MTLCommandBuffer`                                      | Separate `MTLCommandBuffers`                                     |
|---------------------------|----------------------------------------------------------------|------------------------------------------------------------------|
| **Resource Allocation**   | Resources can be shared efficiently among compute functions.   | Resources need to be allocated separately, which can be less efficient. |
| **Synchronization**       | Implicit synchronization for compute functions on the same buffer. | Explicit synchronization may be required between different command buffers. |
| **Execution Order**       | Guaranteed execution order based on command encoding sequence. | Independent execution order, unless explicitly synchronized.     |
| **Dependency Handling**   | Easier to handle dependencies within the same command buffer.   | Dependencies between command buffers need careful management.    |
| **Performance**           | Can be optimal if compute functions can run sequentially without stalling. | May introduce overhead due to setup and teardown of multiple buffers, but can provide parallel execution opportunities. |
| **Resource Management**   | Easier management of transient resources for a single sequence of compute tasks. | More complex management as resources may be needed across multiple command buffers. |
| **Debugging**             | Simplified debugging with a single sequence of commands.        | Potentially more complex due to interactions across multiple command buffers. |
| **Flexibility**           | Limited flexibility for concurrent execution of commands.       | Greater flexibility to execute commands concurrently on different queues. |
| **Submission**            | Single submission point to the GPU.                            | Multiple submissions may introduce overhead but allow for finer-grained control. |

## Next Step

Learn advanced coordinations [here](<doc:Advanced-Coordination>).

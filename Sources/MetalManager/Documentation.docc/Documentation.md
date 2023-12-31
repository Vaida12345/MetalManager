# ``MetalManager``

## Overview

The Metal Manager is an interface for interacting with the `Metal` framework.

Please note that using `Metal` might not always be the best choice. In experiments, it was found that the ``MetalManager/MetalManager/perform(gridSize:)`` methods takes at least `1ms` to complete. Please avoid using `Metal` when the computation size, ie, the `input` and `output` size is small.

`Metal` is most suitable for calculating large quantity of data in parallel.

## Topics

### Guides

- <doc:/tutorials/MetalGuide>

### Manager
- ``MetalManager/MetalManager``

### Creating a manager
- ``MetalManager/MetalManager/init(name:fileWithin:)``

### The workflow
- ``MetalManager/MetalManager/setConstant(_:type:)``
- ``MetalManager/MetalManager/setBuffer(_:)-59eiu``

- <doc:InputVariations>

### Additional Setups
- ``MetalManager/MetalManager/threadsPerThreadGroup``

### Performs calculation
- ``MetalManager/MetalManager/perform(gridSize:)``

# ``MetalManager``

An interface for interacting with the `Metal` framework.

@Metadata {
    @PageColor(yellow)
    
    @SupportedLanguage(swift)
    
    @Available(macOS,       introduced: 10.13)
    @Available(iOS,         introduced: 12.0)
    @Available(tvOS,        introduced: 12.0)
    @Available(macCatalyst, introduced: 13.0)
    @Available(visionOS,    introduced:  1.0)
}


## Overview

`Metal` is most suitable for calculating large quantity of data in parallel.


## Getting Started

`MetalManager` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://www.github.com/Vaida12345/MetalManager.git", branch: "main")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
https://www.github.com/Vaida12345/MetalManager
```


## Topics

### MetalFunction

Initialize and run a function to run on GPU.

- <doc:Running-Metal>
- ``MetalFunction``


- ``MetalContext``

### Serializing Execution
Run multiple functions in batch.

- <doc:Serialized-Execution>
- ``MetalCommandBuffer``

### Advanced Coordinations
Coordinate resources between the CPU and GPU.

- <doc:Advanced-Coordination>
- ``MetalContext``
- ``MetalDependentState``


### Working with SwiftUI

An `Image` with `MTLTexture` as backend.

- ``TextureView``

### Conversion

- <doc:Conversions>


### Implementation Details 

These structures are implementation details, and generally do not concern the users.

- ``MetalArgumentFunction``
- ``MetalFunctionProtocol``
- ``MetalCommandEncoder``


### Manager
The artifact from old implementations. You should run metal without using this structure directly.

- ``MetalManager/MetalManager``

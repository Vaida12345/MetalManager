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

Using `Metal` might not always be the best choice. In experiments, it was found that the ``MetalManager/MetalManager/perform(gridSize:)`` methods takes at least `1ms` to complete. Please avoid using `Metal` when the computation size, ie, the `input` and `output` size is small.

`Metal` is most suitable for calculating large quantity of data in parallel.


## Getting Started

`MetalManager` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/Vaida12345/MetalManager.git", branch: "main")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
https://github.com/Vaida12345/MetalManager
```


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

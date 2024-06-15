# MetalManager

An interface for interacting with the `Metal` framework.

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

## Documentation

This package entails a detailed DocC documentation, with an interactive tutorial for a step-by-step 101.

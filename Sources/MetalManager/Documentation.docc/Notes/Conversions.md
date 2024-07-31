# Conversions

Convert common swift structures with their Metal counterpart.


## Topics

### CGImage

- ``Metal/MTLDevice/makeTexture(from:usage:)``

### MTLTexture
- ``Metal/MTLTexture/makeBuffer(channelsCount:)``
- ``Metal/MTLTexture/makeCGImage(colorSpace:)``

### Arrays

- ``Metal/MTLDevice/makeBuffer(bytesNoCopy:options:)``
- ``Metal/MTLDevice/makeBuffer(of:count:options:)``

### Buffers

- ``Metal/MTLDevice/makeBuffer(bytes:options:)``
- ``Metal/MTLDevice/makeBuffer(bytesNoCopy:options:deallocator:)``

### Conversion Error

- ``MetalResourceCreationError``

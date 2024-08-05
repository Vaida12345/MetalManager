# Conversions

Convert common swift structures with their Metal counterpart.


## Topics

### CGImage

- ``Metal/MTLDevice/makeTexture(from:usage:context:)``

### MTLTexture
- ``Metal/MTLTexture/makeBuffer(channelsCount:bitsPerComponent:)``
- ``Metal/MTLTexture/makeCGImage(channelsCount:bitsPerComponent:colorSpace:bitmapInfo:)``

### Arrays

- ``Metal/MTLDevice/makeBuffer(bytesNoCopy:options:)``
- ``Metal/MTLDevice/makeBuffer(of:count:options:)``

### Buffers

- ``Metal/MTLDevice/makeBuffer(bytes:options:)``
- ``Metal/MTLDevice/makeBuffer(bytesNoCopy:options:deallocator:)``
- ``Metal/MTLBuffer/cast(to:count:)``

### Conversion Error

- ``MetalResourceCreationError``


// MARK: - Prepare

var valueA = 1
var valueB = 1

let input = [Float](repeating: 1, count: 100)

// MARK: - Computation

var manager = try MetalManager(name: "calculation", outputElementType: Float.self)

manager.setConstant(&valueA, type: MTLDataType.int)
manager.setConstant(&valueB, type: MTLDataType.int)

try manager.submitConstants()

manager.setGridSize(width: input.count)

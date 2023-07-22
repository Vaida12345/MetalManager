
// MARK: - Prepare

var valueA = 1
var valueB = 1

// MARK: - Computation

var manager = try MetalManager(name: "calculation", outputElementType: Float.self)

manager.setConstant(&valueA, type: MTLDataType.int)
manager.setConstant(&valueB, type: MTLDataType.int)

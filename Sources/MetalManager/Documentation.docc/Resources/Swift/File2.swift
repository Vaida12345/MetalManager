
// MARK: - Prepare

var alpha = 2.0
var beta = 0.2

// MARK: - Computation

let manager = try MetalManager(name: "linear")

manager.setConstant(&alpha, type: MTLDataType.float)
manager.setConstant(&beta,  type: MTLDataType.float)

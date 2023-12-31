
// MARK: - Prepare

let alpha = 2.0
let beta = 0.2

let input = [Float](repeating: 1, count: 100)

// MARK: - Computation

let manager = try MetalManager(name: "linear")

manager.setConstant(alpha)
manager.setConstant(beta)

let buffer = try manager.setBuffer(input)

try manager.perform(gridSize: MTLSize(width: input.count, height: 1, depth: 1))

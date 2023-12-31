
// MARK: - Prepare

let alpha = 2.0
let beta = 0.2

// MARK: - Computation

let manager = try MetalManager(name: "linear")

manager.setConstant(alpha)
manager.setConstant(beta)

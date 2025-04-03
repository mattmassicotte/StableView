// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "StableView",
	platforms: [
		.macOS(.v12),
		.macCatalyst(.v16),
		.iOS(.v16),
		.tvOS(.v16),
		.visionOS(.v1),
	],
	products: [
		.library(
			name: "StableView", targets: ["StableView"]),
	],
	targets: [
		.target(name: "StableView"),
		.testTarget(name: "StableViewTests", dependencies: ["StableView"]),
	]
)

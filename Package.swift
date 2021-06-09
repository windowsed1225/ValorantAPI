// swift-tools-version:5.5

import PackageDescription

let package = Package(
	name: "ValorantAPI",
	platforms: [
		.macOS("12"),
		.iOS("15"),
	],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "ValorantAPI",
			targets: ["ValorantAPI"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/juliand665/HandyOperators", from: "2.0.0"),
		.package(url: "https://github.com/juliand665/ArrayBuilder", from: "1.0.0"),
		.package(url: "https://github.com/juliand665/Protoquest", .branch("swift-5.5")),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "ValorantAPI",
			dependencies: [
				"HandyOperators",
				"ArrayBuilder",
				"Protoquest",
			]
		),
		.testTarget(
			name: "ValorantAPITests",
			dependencies: ["ValorantAPI"],
			resources: [
				.copy("examples"),
			]
		),
	]
)

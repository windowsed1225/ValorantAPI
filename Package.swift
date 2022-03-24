// swift-tools-version:5.5

import PackageDescription

let package = Package(
	name: "ValorantAPI",
	platforms: [
		.macOS("12.3"),
		.iOS("15.4"),
	],
	products: [
		.library(
			name: "ValorantAPI",
			targets: ["ValorantAPI"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/juliand665/HandyOperators.git", from: "2.1.0"),
		.package(url: "https://github.com/juliand665/ArrayBuilder.git", from: "1.1.0"),
		.package(url: "https://github.com/juliand665/Protoquest.git", .branch("main")),
		.package(url: "https://github.com/juliand665/ErgonomicCodable.git", .branch("main")),
	],
	targets: [
		.target(
			name: "ValorantAPI",
			dependencies: [
				"HandyOperators",
				"ArrayBuilder",
				"Protoquest",
				"ErgonomicCodable",
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

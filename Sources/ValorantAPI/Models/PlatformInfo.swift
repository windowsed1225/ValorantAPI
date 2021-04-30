import Foundation

public struct PlatformInfo: Encodable {
	static let supportedExample = Self(
		type: "PC",
		os: "Windows",
		osVersion: "10.0.19042.1.256.64bit",
		chipset: "Unknown"
	)
	
	var type: String
	var os: String
	var osVersion: String
	var chipset: String
	
	private enum CodingKeys: String, CodingKey {
		case type = "platformType"
		case os = "platformOS"
		case osVersion = "platformOSVersion"
		case chipset = "platformChipset"
	}
}

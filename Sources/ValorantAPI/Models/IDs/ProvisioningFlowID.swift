import Foundation

public struct ProvisioningFlowID: SimpleRawWrapper {
	public static let matchmaking = Self("Matchmaking")
	public static let customGame = Self("CustomGame")
	
	public var rawValue: String
	
	public init(_ rawValue: String) {
		self.rawValue = rawValue
	}
}

import Foundation

public enum ProvisioningFlow {
	public typealias ID = ObjectID<Self, String>
}

public extension ProvisioningFlow.ID {
	static let matchmaking = Self("Matchmaking")
	static let customGame = Self("CustomGame")
}

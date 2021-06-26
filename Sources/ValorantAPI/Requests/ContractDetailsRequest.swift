import Foundation
import Protoquest

extension ValorantClient {
	/// - Note: This request requires that you've set the client version on your client! Use ``setClientVersion(_:)`` for that.
	public func getContractDetails() async throws -> ContractDetails {
		try await send(ContractDetailsRequest(playerID: user.id))
	}
}

private struct ContractDetailsRequest: GetJSONRequest {
	var playerID: Player.ID
	
	var path: String {
		"/contracts/v1/contracts/\(playerID)"
	}
	
	typealias Response = ContractDetails
}

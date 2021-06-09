import Foundation
import Protoquest

extension ValorantClient {
	/// - Note: This request requires that you've set the client version on your client!
	public func getContractDetails(playerID: Player.ID) async throws -> ContractDetails {
		try await send(ContractDetailsRequest(playerID: playerID))
	}
}

private struct ContractDetailsRequest: GetJSONRequest {
	var playerID: Player.ID
	
	var path: String {
		"/contracts/v1/contracts/\(playerID.apiValue)"
	}
	
	typealias Response = ContractDetails
}

import Foundation
import Protoquest

extension ValorantClient {
	/// - Note: This request requires that you've set the client version on your client! Use ``setClientVersion(_:)`` for that.
	public func getContractDetails() async throws -> ContractDetails {
		try await send(ContractDetailsRequest(playerID: userID))
	}
	
	public func activateContract(_ id: Contract.ID) async throws {
		try await send(ActivateContractRequest(playerID: userID, contractID: id))
	}
}

private struct ContractDetailsRequest: GetJSONRequest {
	var playerID: Player.ID
	
	var path: String {
		"/contracts/v1/contracts/\(playerID)"
	}
	
	typealias Response = ContractDetails
}

private struct ActivateContractRequest: GetRequest, StatusCodeRequest {
	var httpMethod: String { "POST" }
	
	var playerID: Player.ID
	var contractID: Contract.ID
	
	var path: String {
		"/contracts/v1/contracts/\(playerID)/special/\(contractID)"
	}
}

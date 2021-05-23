import Foundation
import Protoquest

extension ValorantClient {
	public func getContractDetails(playerID: Player.ID) -> BasicPublisher<ContractDetails> {
		send(ContractDetailsRequest(playerID: playerID))
	}
}

private struct ContractDetailsRequest: GetJSONRequest {
	var playerID: Player.ID
	
	var path: String {
		"/contracts/v1/contracts/\(playerID.apiValue)"
	}
	
	typealias Response = ContractDetails
}

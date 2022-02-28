import Foundation
import Protoquest

extension ValorantClient {
	public func getCareerSummary(userID: User.ID) async throws -> CareerSummary {
		try await send(CareerSummaryRequest(userID: userID))
	}
}

private struct CareerSummaryRequest: GetJSONRequest {
	var userID: Player.ID
	
	var path: String {
		"/mmr/v1/players/\(userID)"
	}
	
	typealias Response = CareerSummary
}

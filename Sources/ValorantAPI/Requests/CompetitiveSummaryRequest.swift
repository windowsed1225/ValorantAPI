import Foundation
import Protoquest

extension ValorantClient {
	public func getCareerSummary(userID: User.ID) async throws -> CareerSummary {
		try await send(CompetitiveSummaryRequest(userID: userID))
	}
}

private struct CompetitiveSummaryRequest: GetJSONRequest {
	var userID: Player.ID
	
	var path: String {
		"/mmr/v1/players/\(userID)"
	}
	
	typealias Response = CareerSummary
}

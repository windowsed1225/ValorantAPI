import Foundation
import Combine
import Protoquest

extension ValorantClient {
	public func getMatchDetails(matchID: Match.ID) -> BasicPublisher<MatchDetails> {
		send(MatchDetailsRequest(matchID: matchID))
	}
}

private struct MatchDetailsRequest: GetJSONRequest {
	var matchID: Match.ID
	
	var path: String {
		"/match-details/v1/matches/\(matchID.apiValue)"
	}
	
	typealias Response = MatchDetails
}

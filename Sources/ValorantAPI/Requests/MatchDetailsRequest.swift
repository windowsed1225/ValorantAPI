import Foundation
import Combine
import HandyOperators
import ArrayBuilder

struct MatchDetailsRequest: GetJSONRequest, GameAPIRequest {
	var matchID: Match.ID
	
	var path: String {
		"/match-details/v1/matches/\(matchID.apiValue)"
	}
	
	typealias Response = MatchDetails
}

extension Client {
	public func getMatchDetails(matchID: Match.ID) -> AnyPublisher<MatchDetails, Error> {
		send(MatchDetailsRequest(matchID: matchID))
	}
}

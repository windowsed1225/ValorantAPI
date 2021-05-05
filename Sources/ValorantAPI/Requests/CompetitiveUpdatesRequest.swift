import Foundation
import Combine
import HandyOperators
import ArrayBuilder

struct CompetitiveUpdatesRequest: GetJSONRequest, GameAPIRequest {
	var userID: Player.ID
	var startIndex = 0
	var endIndex = 20
	
	var path: String {
		"/mmr/v1/players/\(userID.apiValue)/competitiveupdates"
	}
	
	func urlParams() -> [URLParameter] {
		("startIndex", startIndex)
		("endIndex", endIndex)
	}
	
	struct Response: Decodable {
		var version: Int
		var subject: UUID
		var matches: [CompetitiveUpdate]
		
		private enum CodingKeys: String, CodingKey {
			case version = "Version"
			case subject = "Subject"
			case matches = "Matches"
		}
	}
}

extension Client {
	public func getCompetitiveUpdates(userID: Player.ID, startIndex: Int = 0) -> AnyPublisher<[CompetitiveUpdate], Error> {
		send(CompetitiveUpdatesRequest(
			userID: userID,
			startIndex: startIndex, endIndex: startIndex + 20
		))
		.map(\.matches)
		.eraseToAnyPublisher()
	}
}

import Foundation
import Combine
import HandyOperators
import ArrayBuilder

struct MatchHistoryRequest: GetJSONRequest, GameAPIRequest {
	var userID: Player.ID
	var startIndex = 0
	var endIndex = 20
	var queue: QueueID?
	
	var path: String {
		"/match-history/v1/history/\(userID.apiValue)"
	}
	
	func urlParams() -> [URLParameter] {
		("startIndex", startIndex)
		("endIndex", endIndex)
		queue.map { ("queue", $0.rawValue) }
	}
	
	struct Response: Decodable {
		var subject: UUID
		var history: [MatchHistoryEntry]
		
		private enum CodingKeys: String, CodingKey {
			case subject = "Subject"
			case history = "History"
		}
	}
}

extension Client {
	public func getMatchHistory(userID: Player.ID, queue: QueueID? = nil, startIndex: Int = 0) -> AnyPublisher<[MatchHistoryEntry], Error> {
		send(MatchHistoryRequest(
			userID: userID,
			startIndex: startIndex, endIndex: startIndex + 20,
			queue: queue
		))
		.map(\.history)
		.eraseToAnyPublisher()
	}
}

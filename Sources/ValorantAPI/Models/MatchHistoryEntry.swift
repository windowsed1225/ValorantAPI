import Foundation

public struct MatchHistoryEntry: Codable {
	public var matchID: Match.ID
	public var gameStartTime: Date
	public var teamID: Team.ID
	
	private enum CodingKeys: String, CodingKey {
		case matchID = "MatchID"
		case gameStartTime = "GameStartTime"
		case teamID = "TeamID"
	}
}

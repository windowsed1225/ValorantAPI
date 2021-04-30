import Foundation

public struct CompetitiveUpdate: Codable, Identifiable {
	public var id: UUID
	public var mapID: MapID
	public var startTime: Date
	public var tierBeforeUpdate: Int
	public var tierAfterUpdate: Int
	public var tierProgressBeforeUpdate: Int
	public var tierProgressAfterUpdate: Int
	public var ratingEarned: Int
	public var performanceBonus: Int
	public var afkPenalty: Int
	
	public var isRanked: Bool { tierAfterUpdate != 0 }
	
	public var eloChange: Int { eloAfterUpdate - eloBeforeUpdate }
	public var eloBeforeUpdate: Int { tierBeforeUpdate * 100 + tierProgressBeforeUpdate }
	public var eloAfterUpdate: Int { tierAfterUpdate * 100 + tierProgressAfterUpdate }
	
	private enum CodingKeys: String, CodingKey {
		case id = "MatchID"
		case mapID = "MapID"
		case startTime = "MatchStartTime"
		case tierAfterUpdate = "TierAfterUpdate"
		case tierBeforeUpdate = "TierBeforeUpdate"
		case tierProgressAfterUpdate = "RankedRatingAfterUpdate"
		case tierProgressBeforeUpdate = "RankedRatingBeforeUpdate"
		case ratingEarned = "RankedRatingEarned"
		case performanceBonus = "RankedRatingPerformanceBonus"
		case afkPenalty = "AFKPenalty"
	}
}

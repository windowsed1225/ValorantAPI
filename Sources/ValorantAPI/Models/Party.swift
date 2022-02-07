import Foundation
import ErgonomicCodable

public struct Party: Identifiable, Codable {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	
	public var id: ID
	public var members: [Member]
	public var state: String // TODO: enum
	public var accessibility: Accessibility
	public var eligibleQueues: [QueueID]
	@SpecialOptional(.distantPast)
	public var queueEntryTime: Date?
	public var matchmakingData: MatchmakingData
	// there's custom game data here too—handle that?
	
	private enum CodingKeys: String, CodingKey {
		case id = "ID"
		case members = "Members"
		case state = "State"
		case accessibility = "Accessibility"
		case eligibleQueues = "EligibleQueues"
		case queueEntryTime = "QueueEntryTime"
		case matchmakingData = "MatchmakingData"
	}
	
	public struct Member: Identifiable, Codable {
		public var id: Player.ID
		public var identity: Player.Identity
		public var isReady: Bool
		public var isOwner: Bool
		public var isModerator: Bool
		
		private enum CodingKeys: String, CodingKey {
			case id = "Subject"
			case identity = "PlayerIdentity"
			case isReady = "IsReady"
			case isOwner = "IsOwner"
			case isModerator = "IsModerator"
		}
	}
	
	public enum Accessibility: String, Codable {
		case open = "OPEN"
		case closed = "CLOSED"
	}
	
	public struct MatchmakingData: Codable {
		public var queueID: QueueID
		/// RR penalty for skill disparity in Competitive
		public var rrPenalty: Double // TODO: is this actually an int?
		
		private enum CodingKeys: String, CodingKey {
			case queueID = "QueueID"
			case rrPenalty = "SkillDisparityRRPenalty"
		}
	}
}

import Foundation
import ErgonomicCodable

public struct ContractDetails: Codable {
	public var contracts: [Contract]
	public var activeSpecialContract: Contract.ID
	public var missions: [Mission]
	public var missionMetadata: MissionMetadata
	// Technically this object also lists processed matches, but I don't care about those right now and they'd be a significant extra effort to add.
	
	private enum CodingKeys: String, CodingKey {
		case contracts = "Contracts"
		case activeSpecialContract = "ActiveSpecialContract"
		case missions = "Missions"
		case missionMetadata = "MissionMetadata"
	}
	
	public struct MissionMetadata: Codable {
		public var hasCompletedNewPlayerExperience: Bool
		/// The activation date for the last set of weeklies the user has completed.
		/// - Note: Can be `nil` for users that haven't completed any weeklies this act.
		public var weeklyCheckpoint: Date?
		/// When the next set of weekly missions will become available.
		public var weeklyRefillTime: Date?
		
		private enum CodingKeys: String, CodingKey {
			case hasCompletedNewPlayerExperience = "NPECompleted"
			case weeklyCheckpoint = "WeeklyCheckpoint"
			case weeklyRefillTime = "WeeklyRefillTime"
		}
	}
}

public struct Contract: Codable, Identifiable {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	public var id: ID
	
	public var progression: Progression
	public var levelReached: Int
	public var progressionTowardsNextLevel: Int
	
	private enum CodingKeys: String, CodingKey {
		case id = "ContractDefinitionID"
		case progression = "ContractProgression"
		case levelReached = "ProgressionLevelReached"
		case progressionTowardsNextLevel = "ProgressionTowardsNextLevel"
	}
	
	public struct Progression: Codable {
		public var totalEarned: Int
		@StringKeyedDictionary
		public var highestRewardedLevel: [LowercaseUUID: Int]
		
		private enum CodingKeys: String, CodingKey {
			case totalEarned = "TotalProgressionEarned"
			case highestRewardedLevel = "HighestRewardedLevel"
		}
	}
}

public struct Mission: Codable, Identifiable {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	public var id: ID
	
	@StringKeyedDictionary
	public var objectiveProgress: [Objective.ID: Int]
	public var isComplete: Bool
	public var expirationTime: Date
	
	private enum CodingKeys: String, CodingKey {
		case id = "ID"
		case objectiveProgress = "Objectives"
		case isComplete = "Complete"
		case expirationTime = "ExpirationTime"
	}
}

public enum Objective {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}

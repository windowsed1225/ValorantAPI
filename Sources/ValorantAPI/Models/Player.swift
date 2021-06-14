import Foundation

public struct Player: Codable, Identifiable {
	public var id: User.ID
	public var gameName: String
	public var tagLine: String
	public var platformInfo: PlatformInfo
	public var playerCardID: PlayerCard.ID
	public var playerTitleID: PlayerTitle.ID
	
	public var teamID: Team.ID
	public var partyID: Party.ID
	public var agentID: Agent.ID
	public var competitiveTier: Int
	
	public var stats: Stats
	public var damageDealtByRound: [DamageDealt]?
	
	public var sessionPlaytimeMinutes: Int?
	public var behaviorFactors: BehaviorFactors?
	
	public var name: String {
		"\(gameName) #\(tagLine)"
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "subject"
		case gameName
		case tagLine
		case platformInfo
		case teamID = "teamId"
		case partyID = "partyId"
		case agentID = "characterId"
		case stats
		case damageDealtByRound = "roundDamage"
		case competitiveTier
		case playerCardID = "playerCard"
		case playerTitleID = "playerTitle"
		case sessionPlaytimeMinutes
		case behaviorFactors
	}
	
	public struct Stats: Codable {
		public var score: Int
		public var roundsPlayed: Int
		public var kills, deaths, assists: Int
		public var playtimeMillis: Int
		public var abilityCasts: AbilityCasts?
		
		public struct AbilityCasts: Codable {
			public var first, second, signature, ultimate: Int
			
			private enum CodingKeys: String, CodingKey {
				// this naming makes no sense lmao
				case first = "grenadeCasts"
				case second = "ability1Casts"
				case signature = "ability2Casts"
				case ultimate = "ultimateCasts"
			}
		}
	}
	
	public struct DamageDealt: Codable {
		public var round: Int
		public var receiver: Player.ID
		public var damage: Int
	}
	
	public struct BehaviorFactors: Codable {
		public var afkRounds: Double
	}
}

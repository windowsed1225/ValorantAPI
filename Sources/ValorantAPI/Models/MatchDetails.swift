import Foundation
import HandyOperators

public struct MatchDetails: Codable, Identifiable {
	public var matchInfo: MatchInfo
	public var players: [Player]
	public var teams: [Team]
	public var roundResults: [RoundResult]
	public var kills: [Kill]
	
	public var id: Match.ID { matchInfo.id }
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		matchInfo = try container.decodeValue(forKey: .matchInfo)
		players = try container.decodeValue(forKey: .players)
		teams = try container.decodeValue(forKey: .teams)
		roundResults = try container.decode([_RoundResult].self, forKey: .roundResults)
			.map(\.result)
		kills = try container.decodeValue(forKey: .kills)
	}
}

public struct MatchInfo: Codable, Identifiable {
	public var id: Match.ID
	public var mapID: MapID
	public var gameVersion: String
	public var gameLengthMillis: Int
	public var gameStart: Date
	public var provisioningFlowID: String
	public var isCompleted: Bool
	public var queueID: QueueID
	public var gameMode: String
	public var isRanked: Bool
	public var canAdvanceContracts: Bool
	public var seasonID: Season.ID
	
	public var gameLength: TimeInterval {
		TimeInterval(gameLengthMillis) / 1000
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "matchId"
		case mapID = "mapId"
		case gameVersion
		case gameLengthMillis
		case gameStart = "gameStartMillis"
		case provisioningFlowID
		case isCompleted
		case queueID
		case gameMode
		case isRanked
		case canAdvanceContracts = "canProgressContracts"
		case seasonID = "seasonId"
	}
}

public struct Player: Codable, Identifiable {
	public typealias ID = ObjectID<Self, UUID>
	
	public var id: ID
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

public struct Team: Codable {
	public typealias ID = ObjectID<Self, String>
	
	public var id: ID
	public var won: Bool
	public var roundsPlayed, roundsWon: Int
	public var pointCount: Int
	
	private enum CodingKeys: String, CodingKey {
		case id = "teamId"
		case won
		case roundsPlayed
		case roundsWon
		case pointCount = "numPoints"
	}
}

public struct RoundResult: Codable {
	public var number: Int
	
	public var outcome: String
	public var outcomeCode: String
	public var ceremony: String
	public var winningTeam: Team.ID
	
	public var playerEconomies: [PlayerEconomy]?
	public var playerScores: [PlayerScore]?
	public var playerStats: [PlayerStats]
	
	public var plantSite: String?
	public var plant: BombAction?
	public var defusal: BombAction?
	
	public struct BombAction: Codable {
		public var timeMillis: Int
		public var position: Position
		public var playerLocations: [PlayerLocation]
		public var actor: Player.ID
	}
	
	public struct PlayerEconomy {
		public var subject: Player.ID?
		public var spent, remaining: Int
		public var loadoutValue: Int
		public var weapon: Weapon.ID?
		public var armor: Armor.ID?
		// no info on sidearms unfortunately
	}
	
	public struct PlayerScore: Codable {
		public var subject: Player.ID
		public var score: Int
	}
	
	public struct PlayerStats: Codable {
		public var subject: Player.ID
		
		public var kills: [Kill]
		public var damageDealt: [Damage]
		public var combatScore: Int
		public var economy: PlayerEconomy
		
		public var wasAFK: Bool
		public var wasPenalized: Bool
		public var stayedInSpawn: Bool
		
		private enum CodingKeys: String, CodingKey {
			case subject
			
			case kills
			case damageDealt = "damage"
			case combatScore = "score"
			case economy
			// there's also a key here 'abilities' whose nested values always seem to be null, at least in the games i checked lol
			
			case wasAFK = "wasAfk"
			case wasPenalized
			case stayedInSpawn
		}
		
		public struct Damage: Codable {
			public var receiver: Player.ID
			public var damage: Int
			public var headshots: Int
			public var bodyshots: Int
			public var legshots: Int
		}
	}
}

public struct PlayerLocation: Codable {
	public var subject: Player.ID
	/// in radians
	public var angle: Double
	public var position: Position
	
	private enum CodingKeys: String, CodingKey {
		case subject
		case angle = "viewRadians"
		case position = "location"
	}
}

public struct Position: Codable, Hashable {
	public var x, y: Int
}

extension RoundResult.PlayerEconomy: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		subject = try container.decodeValueIfPresent(forKey: .subject)
		spent = try container.decodeValue(forKey: .spent)
		remaining = try container.decodeValue(forKey: .remaining)
		loadoutValue = try container.decodeValue(forKey: .loadoutValue)
		
		let rawWeapon = try container.decodeIfPresent(String.self, forKey: .weapon)
		if rawWeapon?.isEmpty == false {
			weapon = try container.decodeValue(forKey: .weapon)
		}
		
		let rawArmor = try container.decodeIfPresent(String.self, forKey: .armor)
		if rawArmor?.isEmpty == false {
			armor = try container.decodeValue(forKey: .armor)
		}
	}
}

public struct Kill: Codable {
	public var round: Int?
	public var roundTimeMillis: Int
	public var gameTimeMillis: Int
	
	public var killer, victim: Player.ID
	public var assistants: [Player.ID]
	
	public var victimPosition: Position
	public var playerLocations: [PlayerLocation]
	public var finishingDamage: Damage
	
	private enum CodingKeys: String, CodingKey {
		case round
		case roundTimeMillis = "roundTime"
		case gameTimeMillis = "gameTime"
		
		case killer
		case victim
		case assistants
		
		case victimPosition = "victimLocation"
		case playerLocations
		case finishingDamage
	}
	
	public struct Damage: Codable {
		public var type: String
		/// weapon id or ability name/"id", not sure about fall damage
		public var source: String
		public var wasInSecondaryFireMode: Bool
		
		private enum CodingKeys: String, CodingKey {
			case type = "damageType"
			case source = "damageItem"
			case wasInSecondaryFireMode = "isSecondaryFireMode"
		}
	}
}

// Codable sure is a pain sometimes

private struct _RoundResult: Decodable {
	var result: RoundResult
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if decoder.isDecodingFromRiot {
			result = try container.decode(APIRoundResult.self)
				.makeModel(in: container)
		} else {
			result = try container.decode(RoundResult.self)
		}
	}
}

private struct APIRoundResult: Decodable {
	var number: Int
	
	var outcome: String
	var outcomeCode: String
	var ceremony: String
	var winningTeam: Team.ID
	
	var playerEconomies: [RoundResult.PlayerEconomy]?
	var playerScores: [RoundResult.PlayerScore]?
	var playerStats: [RoundResult.PlayerStats]
	
	var plantSite: String
	var plantTimeMillis: Int
	var plantLocation: Position
	var plantPlayerLocations: [PlayerLocation]?
	var planter: Player.ID?
	
	var defuseTimeMillis: Int
	var defuseLocation: Position
	var defusePlayerLocations: [PlayerLocation]?
	var defuser: Player.ID?
	
	func makeModel(in container: SingleValueDecodingContainer) throws -> RoundResult {
		.init(
			number: number,
			outcome: outcome,
			outcomeCode: outcomeCode,
			ceremony: ceremony,
			winningTeam: winningTeam,
			playerEconomies: playerEconomies,
			playerScores: playerScores,
			playerStats: playerStats,
			plantSite: plantSite.isEmpty ? nil : plantSite,
			plant: try planter.map {
				try .init(
					timeMillis: plantTimeMillis,
					position: plantLocation,
					playerLocations: plantPlayerLocations ??? DecodingError.dataCorruptedError(
						in: container,
						debugDescription: "planter is present without plantPlayerLocations"
					),
					actor: $0
				)
			},
			defusal: try defuser.map {
				try .init(
					timeMillis: defuseTimeMillis,
					position: defuseLocation,
					playerLocations: defusePlayerLocations ??? DecodingError.dataCorruptedError(
						in: container,
						debugDescription: "defuser is present without defusePlayerLocations"
					),
					actor: $0
				)
			}
		)
	}
	
	private enum CodingKeys: String, CodingKey {
		case number = "roundNum"
		
		case outcome = "roundResult"
		case outcomeCode = "roundResultCode"
		case ceremony = "roundCeremony"
		case winningTeam
		
		case playerEconomies
		case playerScores
		case playerStats
		
		case plantSite
		case plantTimeMillis = "plantRoundTime"
		case plantLocation
		case plantPlayerLocations
		case planter = "bombPlanter"
		
		case defuseTimeMillis = "defuseRoundTime"
		case defuseLocation
		case defusePlayerLocations
		case defuser = "bombDefuser"
	}
}

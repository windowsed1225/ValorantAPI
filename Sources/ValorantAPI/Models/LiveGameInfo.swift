import Foundation

public struct LiveGameInfo: Codable, BasicMatchInfo {
	public var id: Match.ID
	
	public var players: [PlayerInfo]
	
	public var state: State
	public var mapID: MapID
	public var modeID: GameMode.ID
	public var provisioningFlowID: ProvisioningFlow.ID
	public var matchmakingData: MatchmakingData?
	public var isReconnectable: Bool
	
	public var queueID: QueueID? {
		matchmakingData?.queueID
	}
	
	public var isRanked: Bool {
		matchmakingData?.isRanked ?? false
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "MatchID"
		
		case players = "Players"
		
		case state = "State"
		case mapID = "MapID"
		case modeID = "ModeID"
		case provisioningFlowID = "ProvisioningFlow"
		case matchmakingData = "MatchmakingData"
		case isReconnectable = "IsReconnectable"
	}
	
	public struct State: SimpleRawWrapper {
		static let inProgress = Self("IN_PROGRESS")
		
		public var rawValue: String
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
	}
	
	public struct MatchmakingData: Codable {
		@SpecialOptional(.emptyString)
		public var queueID: QueueID?
		public var isRanked: Bool
		
		private enum CodingKeys: String, CodingKey {
			case queueID = "QueueID"
			case isRanked = "IsRanked"
		}
	}
	
	public struct PlayerInfo: Codable, Identifiable {
		public var id: Player.ID
		
		public var teamID: Team.ID
		public var agentID: Agent.ID
		public var identity: Player.Identity
		
		private enum CodingKeys: String, CodingKey {
			case id = "Subject"
			
			case teamID = "TeamID"
			case agentID = "CharacterID"
			case identity = "PlayerIdentity"
		}
	}
}

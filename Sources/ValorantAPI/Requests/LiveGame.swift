import Foundation
import Protoquest
import HandyOperators

extension ValorantClient {
	/// Gets the live match (or pregame/agent select) a player is currently in. Can only be applied to the currently-signed-in user.
	public func getLiveMatch(for playerID: Player.ID, inPregame: Bool) async throws -> Match.ID? {
		do {
			return try await send(LivePlayerInfoRequest(
				playerID: playerID, inPregame: inPregame, region: region
			)).matchID
		} catch APIError.resourceNotFound {
			return nil
		}
	}
	
	/// Gets the pregame (agent select) info for a match in that state.
	public func getLivePregameInfo(_ matchID: Match.ID) async throws -> LivePregameInfo? {
		try await send(LiveMatchInfoRequest<LivePregameInfo>(
			matchID: matchID, inPregame: true, region: region
		))
	}
	
	/// Gets the live game info for a running match.
	public func getLiveGameInfo(_ matchID: Match.ID) async throws -> LiveGameInfo? {
		try await send(LiveMatchInfoRequest<LiveGameInfo>(
			matchID: matchID, inPregame: false, region: region
		))
	}
	
	/// Selects or locks in an agent.
	public func pickAgent(_ agentID: Agent.ID, in matchID: Match.ID, shouldLock: Bool) async throws {
		try await send(PickAgentRequest(
			matchID: matchID, agentID: agentID,
			shouldLock: shouldLock,
			region: region
		))
	}
	
	/// Selects an agent without locking in.
	public func selectAgent(_ agentID: Agent.ID, in matchID: Match.ID) async throws {
		try await pickAgent(agentID, in: matchID, shouldLock: false)
	}
	
	/// Locks in an agent (ideally previously selected).
	public func lockInAgent(_ agentID: Agent.ID, in matchID: Match.ID) async throws {
		try await pickAgent(agentID, in: matchID, shouldLock: true)
	}
}

private struct LivePlayerInfoRequest: GetJSONRequest, LiveGameRequest {
	var playerID: Player.ID
	var inPregame: Bool
	var region: Region
	
	var path: String {
		"v1/players/\(playerID.apiValue)"
	}
	
	struct Response: Decodable {
		var matchID: Match.ID
		
		private enum CodingKeys: String, CodingKey {
			case matchID = "MatchID"
		}
	}
}

private struct LiveMatchInfoRequest<Response: Decodable>: GetJSONRequest, LiveGameRequest {
	var matchID: Match.ID
	var inPregame: Bool
	var region: Region
	
	var path: String {
		"v1/matches/\(matchID.apiValue)"
	}
}

private struct PickAgentRequest: GetRequest, StatusCodeRequest, LiveGameRequest {
	var httpMethod: String { "POST" }
	
	var matchID: Match.ID
	var agentID: Agent.ID
	var shouldLock: Bool
	
	var inPregame: Bool { true }
	var region: Region
	
	var path: String {
		"v1/matches/\(matchID.apiValue)/\(shouldLock ? "lock" : "select")/\(agentID.apiValue)"
	}
}

private protocol LiveGameRequest: Request {
	var region: Region { get }
	var inPregame: Bool { get }
}

private let liveGameDecoder = JSONDecoder() <- {
	$0.keyDecodingStrategy = .convertFromUppercase
}

extension JSONDecoder.KeyDecodingStrategy {
	static let convertFromUppercase = custom { path in
		let key = path.last!.stringValue
		return AnyKey(
			stringValue: (key.first?.lowercased() ?? "")
				+ key.dropFirst()
		)!
	}
	
	/// This should really be in `Foundation` already…
	private struct AnyKey: CodingKey {
		var stringValue: String
		var intValue: Int?
		
		init?(stringValue: String) {
			self.stringValue = stringValue
			self.intValue = nil
		}
		
		init?(intValue: Int) {
			self.stringValue = String(intValue)
			self.intValue = intValue
		}
	}
}

extension LiveGameRequest {
	var baseURLOverride: URL? {
		BaseURLs.liveGameAPI(region: region)
			.appendingPathComponent(inPregame ? "pregame" : "core-game")
	}
}

extension LiveGameRequest where Self: JSONDecodingRequest {
	func decodeResponse(from raw: Protoresponse) throws -> Response {
		try raw.decodeJSON(using: liveGameDecoder)
	}
}

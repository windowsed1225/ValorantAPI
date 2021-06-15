import XCTest
import Protoquest
@testable import ValorantAPI

final class ValorantAPITests: XCTestCase {
	static let playerID = Player.ID(stringValue: "3fa8598d-066e-5bdb-998c-74c015c5dba5")!
	static let liveMatchID = Match.ID(stringValue: "a6e7cba8-a4ef-4aae-b775-4eb61e43a0d1")!
	
	func testAuthentication() async throws {
		_ = try await authenticate()
	}
	
	func testLiveNoGame() async throws {
		let client = try await authenticate()
		
		try await testCommunication {
			let matchID = try await client.getLiveMatch(for: Self.playerID, inPregame: true)
			XCTAssertNil(matchID)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/pregame/v1/players/3fa8598d-066e-5bdb-998c-74c015c5dba5")
				.responseCode(404)
				.responseBody(fileNamed: "responses/resource_not_found")
		}
	}
	
	func testLivePregame() async throws {
		let client = try await authenticate()
		
		let matchID = try await testCommunication {
			try await client.getLiveMatch(for: Self.playerID, inPregame: true)!
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/pregame/v1/players/3fa8598d-066e-5bdb-998c-74c015c5dba5")
				.responseBody(fileNamed: "responses/live_player_info")
		}
		XCTAssertEqual(matchID, Self.liveMatchID)
		
		let matchInfo = try await testCommunication {
			try await client.getLivePregameInfo(matchID)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/pregame/v1/matches/a6e7cba8-a4ef-4aae-b775-4eb61e43a0d1")
				.responseBody(fileNamed: "pregame_match")
		}
		
		XCTAssertEqual(matchInfo.id, matchID)
		XCTAssert(matchInfo.team.players.map(\.id).contains(Self.playerID))
	}
	
	func testLiveGame() async throws {
		let client = try await authenticate()
		
		let matchID = try await testCommunication {
			try await client.getLiveMatch(for: Self.playerID, inPregame: false)!
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/core-game/v1/players/3fa8598d-066e-5bdb-998c-74c015c5dba5")
				.responseBody(fileNamed: "responses/live_player_info")
		}
		XCTAssertEqual(matchID, Self.liveMatchID)
		
		let matchInfo = try await testCommunication {
			try await client.getLiveGameInfo(matchID)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/core-game/v1/matches/a6e7cba8-a4ef-4aae-b775-4eb61e43a0d1")
				.responseBody(fileNamed: "live_match")
		}
		
		XCTAssertEqual(matchInfo.id, matchID)
		XCTAssert(matchInfo.players.map(\.id).contains(Self.playerID))
	}
	
	func authenticate() async throws -> ValorantClient {
		try await testCommunication {
			try await ValorantClient.authenticated(
				username: "username", password: "password",
				region: .europe,
				sessionOverride: verifyingURLSession
			)
		} expecting: {
			ExpectedRequest(to: "https://auth.riotgames.com/api/v1/authorization")
				.post()
				.responseBody(#"{ "type": "auth", "country": "che" }"#)
			
			ExpectedRequest(to: "https://auth.riotgames.com/api/v1/authorization")
				.put()
				.responseBody(fileNamed: "responses/access_token")
			
			ExpectedRequest(to: "https://entitlements.auth.riotgames.com/api/token/v1")
				.post()
				.responseBody(#"{ "entitlements_token": "ENTITLEMENTS_TOKEN" }"#)
		}
	}
}

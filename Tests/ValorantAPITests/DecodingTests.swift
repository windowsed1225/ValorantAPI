import XCTest
@testable import ValorantAPI

final class DecodingTests: XCTestCase {
	func testDecodingCompUpdates() throws {
		let response = try decode(CompetitiveUpdatesRequest.Response.self, fromJSONNamed: "comp_updates")
		XCTAssertEqual(response.matches.count, 20)
	}
	
	func testDecodingMatch() throws {
		let details = try decode(MatchDetails.self, fromJSONNamed: "match")
		//dump(details)
		XCTAssertEqual(details.players.count, 10)
	}
	
	func testDecodingEscalation() throws {
		let details = try decode(MatchDetails.self, fromJSONNamed: "escalation")
		dump(details)
		XCTAssertEqual(details.players.count, 10)
	}
	
	private func decode<Value>(
		_ value: Value.Type = Value.self,
		fromJSONNamed filename: String
	) throws -> Value where Value: Decodable {
		let url = Bundle.module.url(forResource: "examples/\(filename)", withExtension: "json")!
		let json = try Data(contentsOf: url)
		return try Client.responseDecoder.decode(Value.self, from: json)
	}
}

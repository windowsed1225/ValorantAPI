import XCTest
@testable import ValorantAPI

final class DecodingTests: XCTestCase {
	func testDecodingCompUpdates() throws {
		let response = try decode(CompetitiveUpdatesRequest.Response.self, fromJSONNamed: "examples/comp_updates")
		assert(response.matches.count == 20)
	}
	
	private func decode<Value>(
		_ value: Value.Type = Value.self,
		fromJSONNamed filename: String
	) throws -> Value where Value: Decodable {
		let url = Bundle.module.url(forResource: filename, withExtension: "json")!
		let json = try Data(contentsOf: url)
		return try JSONDecoder().decode(Value.self, from: json)
	}
}

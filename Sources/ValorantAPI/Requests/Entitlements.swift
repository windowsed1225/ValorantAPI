import Foundation
import Protoquest

extension Protoclient {
	func getEntitlementsToken() async throws -> String {
		try await send(EntitlementsTokenRequest()).entitlementsToken
	}
}

private struct EntitlementsTokenRequest: JSONJSONRequest, Encodable {
	var baseURLOverride: URL? { BaseURLs.entitlements }
	var path: String { "token/v1" }
	
	struct Response: Decodable {
		var entitlementsToken: String
	}
}

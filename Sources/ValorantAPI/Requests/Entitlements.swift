import Foundation
import Combine
import Protoquest

extension Protoclient {
	func getEntitlementsToken() -> BasicPublisher<String> {
		send(EntitlementsTokenRequest())
			.map(\.entitlementsToken)
			.eraseToAnyPublisher()
	}
}

private struct EntitlementsTokenRequest: JSONJSONRequest, Encodable {
	var baseURLOverride: URL? { BaseURLs.entitlements }
	var path: String { "token/v1" }
	
	struct Response: Decodable {
		var entitlementsToken: String
	}
}

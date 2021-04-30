import Foundation
import Combine

struct EntitlementsTokenRequest: JSONJSONRequest {
	func url(for client: Client) -> URL {
		BaseURLs.entitlements.appendingPathComponent("token/v1")
	}
	
	struct Response: Decodable {
		var entitlementsToken: String
	}
}

extension Client {
	func getEntitlementsToken() -> AnyPublisher<String, Error> {
		send(EntitlementsTokenRequest())
			.map(\.entitlementsToken)
			.eraseToAnyPublisher()
	}
}

import Foundation
import Protoquest

extension ValorantClient {
	public func getUsers(for ids: [User.ID]) async throws -> [User] {
		try await send(UserInfoRequest(body: ids.map(\.apiValue)))
	}
}

private struct UserInfoRequest: JSONJSONRequest {
	var httpMethod: String { "PUT" }
	
	var path: String { "name-service/v2/players"}
	
	var body: [String]
	
	typealias Response = [User]
}

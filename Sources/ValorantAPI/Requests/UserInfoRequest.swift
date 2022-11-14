import Foundation
import Protoquest

extension ValorantClient {
	public func getUsers(for ids: [User.ID]) async throws -> [User] {
		try await send(UserInfoRequest(body: ids))
	}
}

private struct UserInfoRequest: JSONJSONRequest, GameDataRequest {
	var httpMethod: String { "PUT" }
	
	var path: String { "name-service/v2/players" }
	
	var body: [User.ID]
	
	typealias Response = [User]
}

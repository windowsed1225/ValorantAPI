import Foundation
import Protoquest

extension ValorantClient {
	public func getUserInfo() async throws -> UserInfo {
		try await send(OwnUserInfoRequest())
	}
	
	public func getUsers(for ids: [User.ID]) async throws -> [User] {
		try await send(UserInfoRequest(body: ids.map(\.apiValue)))
	}
}

private struct OwnUserInfoRequest: JSONJSONRequest, Encodable {
	var baseURLOverride: URL? { BaseURLs.auth }
	var path: String { "userinfo" }
	
	typealias Response = UserInfo
}

private struct UserInfoRequest: JSONJSONRequest {
	var httpMethod: String { "PUT" }
	
	var path: String { "name-service/v2/players"}
	
	var body: [String]
	
	typealias Response = [User]
}

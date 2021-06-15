import Foundation
import Protoquest

extension ValorantClient {
	public func getUserInfo() async throws -> UserInfo {
		try await send(OwnUserInfoRequest())
	}
	
	public func getUsers(for ids: [User.ID]) async throws -> [User] {
		try await send(UserInfoRequest(body: ids))
	}
}

private struct OwnUserInfoRequest: JSONJSONRequest, Encodable {
	var baseURLOverride: URL? { BaseURLs.auth }
	var path: String { "userinfo" }
	
	typealias Response = UserInfo
}

private struct UserInfoRequest: JSONJSONRequest {
	var path: String { "name-service/v2/players"}
	
	var body: [User.ID]
	
	typealias Response = [User]
}

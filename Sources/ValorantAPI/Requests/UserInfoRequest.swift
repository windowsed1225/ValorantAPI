import Foundation
import Protoquest

extension ValorantClient {
	public func getUserInfo() async throws -> UserInfo {
		try await send(UserInfoRequest())
	}
}

private struct UserInfoRequest: JSONJSONRequest, Encodable {
	var baseURLOverride: URL? { BaseURLs.auth }
	var path: String { "userinfo" }
	
	typealias Response = UserInfo
}

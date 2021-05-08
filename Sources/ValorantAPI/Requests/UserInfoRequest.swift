import Foundation
import Combine
import Protoquest

extension ValorantClient {
	public func getUserInfo() -> BasicPublisher<UserInfo> {
		send(UserInfoRequest())
	}
}

private struct UserInfoRequest: JSONJSONRequest, Encodable {
	var baseURLOverride: URL? { BaseURLs.auth }
	var path: String { "userinfo" }
	
	typealias Response = UserInfo
}

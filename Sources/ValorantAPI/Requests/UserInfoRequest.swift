import Foundation
import Combine

struct UserInfoRequest: JSONJSONRequest {
	func url(for client: Client) -> URL {
		BaseURLs.auth.appendingPathComponent("userinfo")
	}
	
	typealias Response = UserInfo
}

extension Client {
	func getUserInfo() -> AnyPublisher<UserInfo, Error> {
		send(UserInfoRequest())
	} 
}

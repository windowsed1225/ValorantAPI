import Foundation
import HandyOperators
import Protoquest

extension Protoclient {
	func establishSession() async throws -> Void {
		let response = try await send(CookiesRequest())
		assert(response.type == .auth && response.error == nil)
	}
	
	func getAccessToken(username: String, password: String) async throws -> String {
		let response = try await send(AccessTokenRequest(username: username, password: password))
		
		guard response.type != .auth else {
			throw AuthenticationError(message: response.error ?? "<no message given>")
		}
		assert(response.type == .response && response.error == nil)
		
		return response.response!.extractAccessToken()
	}
}

public struct AuthenticationError: LocalizedError {
	static var messageOverrides = [
		"auth_failure": "Invalid username or password."
	]
	
	public var message: String
	
	public var errorDescription: String? {
		Self.messageOverrides[message] ?? message
	}
}

private struct CookiesRequest: JSONJSONRequest, Encodable {
	typealias Response = AuthenticationResponse
	
	var baseURLOverride: URL? { BaseURLs.authAPI }
	var path: String { "authorization" }
	
	let clientID = "play-valorant-web-prod"
	let responseType = "token id_token"
	let redirectURI = "https://playvalorant.com/"
	let nonce = 1
	let scope = "account openid"
}

private struct AccessTokenRequest: JSONJSONRequest, Encodable {
	typealias Response = AuthenticationResponse
	
	var httpMethod: String { "PUT" }
	var baseURLOverride: URL? { BaseURLs.authAPI }
	var path: String { "authorization" }
	
	let type = AuthMessageType.auth
	var username, password: String
}

private struct AuthenticationResponse: Decodable {
	var type: AuthMessageType
	
	var error: String?
	var response: AccessTokenInfo?
	
	struct AccessTokenInfo: Decodable {
		var mode: String // fragment
		var parameters: Parameters
		
		func extractAccessToken() -> String {
			assert(mode == "fragment")
			
			let components = URLComponents(url: parameters.uri, resolvingAgainstBaseURL: false)!
			let values = [String: String](
				uniqueKeysWithValues: components.fragment!
					.split(separator: "&")
					.map {
						let parts = $0.components(separatedBy: "=")
						assert(parts.count == 2)
						return (parts.first!, parts.last!)
					}
			)
			
			return "\(values["token_type"]!) \(values["access_token"]!)"
		}
		
		struct Parameters: Decodable {
			var uri: URL
		}
	}
}

private struct CommunicationMetadata: Codable {
	var type: AuthMessageType
	var country: String
}

private enum AuthMessageType: String, Hashable, Codable {
	case auth
	case response
	case error
}

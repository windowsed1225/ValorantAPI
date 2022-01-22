import Foundation
import HandyOperators
import Protoquest

extension AuthClient {
	func establishSession() async throws {
		let response = try await send(CookiesRequest())
		assert(response.type == .auth && response.error == nil)
	}
	
	func getAccessToken(username: String, password: String) async throws -> AccessToken {
		let response = try await send(AccessTokenRequest(username: username, password: password))
		
		guard response.type != .auth else {
			throw AuthenticationError(message: response.error ?? "<no message given>")
		}
		assert(response.type == .response && response.error == nil)
		
		return response.response!.extractAccessToken()
	}
	
	func refreshAccessToken() async throws -> AccessToken {
		let response = try await send(ReauthenticationRequest())
		print("response:", response)
		let url = try URL(string: response.components(separatedBy: " ").last!)
		??? ReauthenticationError.noURLReceived
		return try url.extractAccessToken()
		??? ReauthenticationError.invalidURLReceived
	}
}

enum ReauthenticationError: Error, LocalizedError {
	case noURLReceived
	case invalidURLReceived
	
	var errorDescription: String? {
		switch self {
		case .noURLReceived:
			return "reauth failed: no url received!"
		case .invalidURLReceived:
			return "reauth failed: invalid url received"
		}
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
	let nonce = 1 // TODO: this feels wrong, not sure what the nonce would be for though
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
		
		func extractAccessToken() -> AccessToken {
			assert(mode == "fragment")
			return parameters.uri.extractAccessToken()!
		}
		
		struct Parameters: Decodable {
			var uri: URL
		}
	}
}

private struct ReauthenticationRequest: GetStringRequest {
	var baseURLOverride: URL? { BaseURLs.auth }
	var path: String { "authorize" }
	
	var urlParams: [URLParameter] {
		let base = CookiesRequest()
		("client_id", base.clientID)
		("response_type", base.responseType)
		("redirect_uri", base.redirectURI)
		("nonce", base.nonce)
		("scope", base.scope)
	}
}

extension URL {
	func collectQueryItems() -> [String: String] {
		.init(
			uniqueKeysWithValues: URLComponents(url: self, resolvingAgainstBaseURL: false)!
				.fragment!
				.split(separator: "&")
				.map {
					let parts = $0.components(separatedBy: "=")
					assert(parts.count == 2)
					return (parts.first!, parts.last!)
				}
		)
	}
	
	func extractAccessToken() -> AccessToken? {
		let values = collectQueryItems()
		guard
			let type = values["token_type"],
			let token = values["access_token"],
			let duration = values["expires_in"].flatMap(Int.init)
		else { return nil }
		return .init(
			type: type,
			token: token,
			expiration: .init(timeIntervalSinceNow: .init(duration) - 30) // 30s tolerance to make sure we don't try to use an expired token
		)
	}
}

private enum AuthMessageType: String, Hashable, Codable {
	case auth
	case response
	case error
}

import Foundation
import HandyOperators
import Protoquest

extension AuthClient {
	func establishSession() async throws {
		let response = try await send(CookiesRequest())
		assert(response.type == .auth && response.error == nil)
	}
	
	func getAccessToken(
		username: String, password: String,
		multifactorHandler: MultifactorHandler
	) async throws -> AccessToken {
		let response = try await send(CredentialsAuthRequest(
			username: username, password: password
		))
		return try await handleAuthResponse(response, multifactorHandler: multifactorHandler)
	}
	
	private func handleAuthResponse(
		_ response: AuthResponse,
		multifactorHandler: MultifactorHandler
	) async throws -> AccessToken {
		switch response.type {
		case .auth:
			throw AuthenticationError(message: response.error ?? "<no message given>")
		case .error:
			throw AuthHandlingError.unexpectedError(response.error)
		case .multifactor:
			assert(response.error == nil)
			guard let info = response.multifactor
			else { throw AuthHandlingError.missingResponseBody }
			let code = try await multifactorHandler(info)
			let newResponse = try await send(MultifactorAuthRequest(
				code: code, rememberDevice: true
			))
			return try await handleAuthResponse(newResponse, multifactorHandler: multifactorHandler)
		case .response:
			assert(response.error == nil)
			guard let body = response.response
			else { throw AuthHandlingError.missingResponseBody }
			return body.extractAccessToken()
		}
	}
	
	func refreshAccessToken() async throws -> AccessToken {
		let response = try await send(ReauthRequest())
		print("response:", response)
		let url = try URL(string: response.components(separatedBy: " ").last!)
		??? AuthHandlingError.missingResponseBody
		return try url.extractAccessToken()
		??? AuthHandlingError.invalidTokenURL(url)
	}
}

enum AuthHandlingError: Error {
	case missingResponseBody
	case invalidTokenURL(URL)
	case unexpectedError(String?)
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
	typealias Response = AuthResponse
	
	var baseURLOverride: URL? { BaseURLs.authAPI }
	var path: String { "authorization" }
	
	let clientID = "play-valorant-web-prod"
	let responseType = "token id_token"
	let redirectURI = "https://playvalorant.com/"
	let nonce = 1 // TODO: this feels wrong, not sure what the nonce would be for though
	let scope = "account openid"
}

private protocol AuthRequest: JSONJSONRequest, Encodable
where Response == AuthResponse {
	var type: AuthMessageType { get }
}

extension AuthRequest {
	var httpMethod: String { "PUT" }
	var baseURLOverride: URL? { BaseURLs.authAPI }
	var path: String { "authorization" }
}

private struct CredentialsAuthRequest: AuthRequest {
	let type = AuthMessageType.auth
	let username, password: String
}

private struct MultifactorAuthRequest: AuthRequest {
	let type = AuthMessageType.multifactor
	let code: String
	let rememberDevice: Bool
}

private struct AuthResponse: Decodable {
	var type: AuthMessageType
	
	var error: String?
	var response: AccessTokenInfo?
	var multifactor: MultifactorInfo?
	
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

public typealias MultifactorHandler = (MultifactorInfo) async throws -> String
public struct MultifactorInfo: Decodable, Hashable {
	public var version: String
	public var codeLength: Int
	/// the method the server has chosen (currently always expected to be email)
	public var method: String
	/// other methods that are available (no way to select them currently)
	public var methods: [String]
	/// the email the code was sent to; mostly blanked-out
	public var email: String
	
	public static func mocked(codeLength: Int, email: String) -> Self {
		.init(
			version: "v2",
			codeLength: codeLength,
			method: "email",
			methods: ["email"],
			email: email
		)
	}
	
	private enum CodingKeys: String, CodingKey {
		case version = "mfaVersion"
		case codeLength = "multiFactorCodeLength"
		case method, methods
		case email
	}
}

private struct ReauthRequest: GetStringRequest {
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
	case multifactor
}

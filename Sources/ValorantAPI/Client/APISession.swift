import Foundation
import HandyOperators

public struct APISession: Codable, Equatable {
	var accessToken: AccessToken
	var entitlementsToken: String
	var cookies: [Cookie]
	var location: Location
	var userID: User.ID
}

struct Cookie: Codable, Hashable {
	var name: String
	var value: String
	var domain: String
	var path: String
	
	init(_ httpCookie: HTTPCookie) {
		name = httpCookie.name
		value = httpCookie.value
		domain = httpCookie.domain
		path = httpCookie.path
	}
	
	var httpCookie: HTTPCookie {
		.init(properties: [
			.name: name,
			.value: value,
			.domain: domain,
			.path: path,
		])!
	}
}

struct AccessToken: Codable, Hashable {
	var type: String
	var token: String
	var expiration: Date
	
	var encoded: String {
		"\(type) \(token)"
	}
	
	var hasExpired: Bool {
		expiration < .now
	}
}

extension APISession {
	public init(
		username: String, password: String,
		urlSessionOverride: URLSession? = nil,
		multifactorHandler: MultifactorHandler
	) async throws {
		let client = await AuthClient(urlSessionOverride: urlSessionOverride)
		try await client.establishSession()
		
		self.accessToken = try await client.getAccessToken(
			username: username, password: password,
			multifactorHandler: multifactorHandler
		)
		await client.setAccessToken(accessToken)
		
		self.entitlementsToken = try await client
			.getEntitlementsToken()
		
		(self.userID, self.location) = try await client.getUserInfo()
		
		self.cookies = await client.cookies().map(Cookie.init)
	}
	
	mutating func refreshAccessToken() async throws {
		let client = await AuthClient()
		await client.setCookies(cookies.map(\.httpCookie))
		self.accessToken = try await client.refreshAccessToken()
		??? RefreshError.sessionExpired
	}
	
	enum EstablishmentError: Error {
		case noSessionIDCookie
		case noTDIDCookie
	}
	
	enum RefreshError: Error {
		case sessionExpired
	}
}

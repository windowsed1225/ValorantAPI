import Foundation
import HandyOperators

public struct APISession: Codable {
	var credentials: Credentials
	var accessToken: AccessToken
	var entitlementsToken: String
	var cookies: [Cookie]
	var location: Location
	public let userID: User.ID
	/// Set to true when the session realizes it has expired unrecoverably (requiring a credentials change or MFA input).
	public private(set) var hasExpired = false
	
#if DEBUG
	/// A mocked session with bogus data, for testing.
	public static let mocked = Self(
		credentials: .init(),
		accessToken: .init(type: "", token: "", idToken: "", expiration: .distantFuture),
		entitlementsToken: "",
		cookies: [],
		location: .europe,
		userID: .init()
	)
#endif
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
	var idToken: String = "" // TODO: temporarily defaulting since we don't need this for already-signed-in users and this maintains backwards compatibility with stored sessions
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
		credentials: Credentials,
		withCookiesFrom other: APISession? = nil,
		urlSessionOverride: URLSession? = nil,
		multifactorHandler: MultifactorHandler
	) async throws {
		self.credentials = credentials
		
		let client = await AuthClient(urlSessionOverride: urlSessionOverride)
		if let other {
			await client.setCookies(other.cookies.map(\.httpCookie))
		} else {
			try await client.establishSession()
		}
		
		let accessToken = try await client.getAccessToken(
			credentials: credentials,
			multifactorHandler: multifactorHandler
		)
		self.accessToken = accessToken
		await client.setAccessToken(accessToken)
		
		// parallelization!
		async let entitlement = client.getEntitlementsToken()
		async let userID = client.getUserID()
		async let location = client.getLocation(using: accessToken)
		self.entitlementsToken = try await entitlement
		self.userID = try await userID
		self.location = try await location
		
		self.cookies = await client.cookies().map(Cookie.init)
	}
	
	mutating func refreshAccessToken() async throws {
		let client = await AuthClient()
		await client.setCookies(cookies.map(\.httpCookie))
		do {
			if let token = try? await client.refreshAccessToken() {
				accessToken = token
			} else {
				// try signing in again, with the same cookies
				accessToken = try await client.getAccessToken(
					credentials: credentials,
					multifactorHandler: { _ in throw RefreshError.sessionExpired }
				)
			}
		} catch {
			hasExpired = true
			throw RefreshError.sessionExpired
		}
	}
	
	enum RefreshError: Error {
		case sessionExpired
	}
}

import Foundation
import HandyOperators

public struct APISession: Codable {
	public let credentials: Credentials
	var accessToken: AccessToken
	var entitlementsToken: String
	var cookies: [Cookie]
	var location: Location
	public let userID: User.ID
	/// Set to true when the session realizes it has expired unrecoverably (requiring a credentials change or MFA input).
	public internal(set) var hasExpired = false
	
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

struct Cookie: Hashable {
	var httpCookie: HTTPCookie
	var name: String { httpCookie.name }
}

extension Cookie: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		// backwards compatibility with existing cookies, for now
		do {
			let old = try container.decode(OldCookie.self)
			self.httpCookie = old.httpCookie
			return
		} catch {}
		
		let raw = try container.decode(Data.self)
		
		guard let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [HTTPCookie.self], from: raw) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "invalid cookie data")
		}
		self.httpCookie = decoded as! HTTPCookie
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		let raw = try NSKeyedArchiver.archivedData(
			withRootObject: httpCookie,
			requiringSecureCoding: false
		)
		try container.encode(raw)
	}
	
	private struct OldCookie: Codable, Hashable {
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
}

struct AccessToken: Codable, Hashable {
	var type: String
	var token: String
	var idToken: String
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
	
	mutating func refreshAccessToken(multifactorHandler: MultifactorHandler) async throws {
		let client = await AuthClient()
		await client.setCookies(cookies.map(\.httpCookie))
		accessToken = try await client.getAccessToken(
			credentials: credentials,
			multifactorHandler: multifactorHandler
		)
		
		cookies = await client.cookies().map(Cookie.init)
	}
}

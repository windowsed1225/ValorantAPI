import Foundation
import HandyOperators
import Protoquest

public final class ValorantClient: Identifiable, Codable {
	/// The decoder used to decode JSON data received from Riot's servers.
	public static let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
		$0.dateDecodingStrategy = .iso8601OrTimestamp
		$0.userInfo[.isDecodingFromRiot] = true
	}
	
	/// Attempts to authenticate with the given credentials and, as a result, publishes a client instance initialized with the necessary tokens.
	public static func authenticated(
		username: String, password: String,
		region: Region,
		sessionOverride: URLSession? = nil
	) async throws -> ValorantClient {
		let client = try await Client.authenticated(
			username: username, password: password,
			region: region,
			sessionOverride: sessionOverride
		)
		return Self(client: client)
	}
	
	private let client: Client
	
	var region: Region { client.region }
	
	private init(client: Client) {
		self.client = client
	}
	
	func send<R: Request>(_ request: R) async throws -> R.Response {
		try await client.send(request)
	}
	
	public func setClientVersion(_ version: String) {
		client.clientVersion = version
	}
	
	/// An error received from Riot's API.
	public enum APIError: Error {
		/// This is outputted for 401 error codes, which the API sometimes responds with instead of providing actual error information… It usually also means you need to reauthenticate.
		case unauthorized
		/// This likely means your access token has expired.
		case tokenFailure(message: String)
		/// The service is currently down for scheduled maintenance.
		case scheduledDowntime(message: String)
		/// The API could not find a resource at the given location—likely code 404, though we only check the associated ``RiotError/errorCode``.
		case resourceNotFound
		/// A non-200 response code was received. If the API returned a valid error JSON, the provided error is passed on here.
		case badResponseCode(Int, Protoresponse, RiotError?)
		/// You were rate-limited for sending too many requests. If provided, `retryAfter` indicates after how many seconds the limit should be lifted again.
		case rateLimited(retryAfter: Int?)
	}
}

/// How Riot's API represents an error it encountered.
public struct RiotError: Decodable {
	/// A programmer-facing representation of the error that occurred, in `SCREAMING_SNAKE_CASE`.
	public var errorCode: String
	/// A human-readable description of the error.
	public var message: String
}

// TODO: make this an actor to avoid data races
private final class Client: Identifiable, Protoclient, Codable {
	typealias APIError = ValorantClient.APIError
	
	static let requestEncoder = JSONEncoder() <- {
		$0.keyEncodingStrategy = .convertToSnakeCase
	}
	var requestEncoder: JSONEncoder { Self.requestEncoder }
	
	var responseDecoder: JSONDecoder { ValorantClient.responseDecoder }
	
	let region: Region
	private(set) var session: URLSession = .init(configuration: .ephemeral)
	
	fileprivate var accessToken: String?
	fileprivate var entitlementsToken: String?
	fileprivate var clientVersion: String?
	
	var baseURL: URL { BaseURLs.gameAPI(region: region) }
	
	static func authenticated(
		username: String, password: String,
		region: Region,
		sessionOverride: URLSession? = nil
	) async throws -> Client {
		let client = Client(region: region, sessionOverride: sessionOverride)
		try await client.establishSession()
		
		client.accessToken = try await client.getAccessToken(username: username, password: password)
		client.entitlementsToken = try await client.getEntitlementsToken()
		return client
	}
	
	private init(region: Region, sessionOverride: URLSession? = nil) {
		self.region = region
		if let sessionOverride = sessionOverride {
			self.session = sessionOverride
		}
	}
	
	private static let encodedPlatformInfo = try! JSONEncoder()
		.encode(PlatformInfo.supportedExample)
		.base64EncodedString()
	
	func addHeaders(to rawRequest: inout URLRequest) {
		if let token = accessToken {
			rawRequest.setValue(token, forHTTPHeaderField: "Authorization")
		}
		if let token = entitlementsToken {
			rawRequest.setValue(token, forHTTPHeaderField: "X-Riot-Entitlements-JWT")
		}
		if let version = clientVersion {
			rawRequest.setValue(version, forHTTPHeaderField: "X-Riot-ClientVersion")
		}
		rawRequest.setValue(Self.encodedPlatformInfo, forHTTPHeaderField: "X-Riot-ClientPlatform")
	}
	
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) async throws -> Protoresponse {
		let (data, rawResponse) = try await session.data(for: rawRequest)
		let response = wrapResponse(data: data, response: rawResponse)
		
		let code = response.httpMetadata!.statusCode
		guard code != 200 else { return response }
		
		// error handling
		
		if let error = try? response.decodeJSON(as: RiotError.self) {
			switch error.errorCode {
			case "BAD_CLAIMS":
				throw APIError.tokenFailure(message: error.message)
			case "SCHEDULED_DOWNTIME":
				throw APIError.scheduledDowntime(message: error.message)
			case "RESOURCE_NOT_FOUND":
				throw APIError.resourceNotFound
			default:
				throw APIError.badResponseCode(code, response, error)
			}
		} else {
			switch code {
			case 401:
				throw APIError.unauthorized
			case 429:
				throw APIError.rateLimited(
					retryAfter: response.httpMetadata!
						.value(forHTTPHeaderField: "Retry-After")
						.flatMap(Int.init)
				)
			default:
				throw APIError.badResponseCode(code, response, nil)
			}
		}
	}
	
	#if DEBUG
	func traceOutgoing<R>(_ rawRequest: URLRequest, for request: R) where R : Request {
		print("sending request to", rawRequest.url!)
	}
	#endif
	
	private enum CodingKeys: CodingKey {
		case region
		case accessToken
		case entitlementsToken
		case clientVersion
	}
}

private extension CodingUserInfoKey {
	static var isDecodingFromRiot = Self(rawValue: "isDecodingFromRiot")!
}

extension Decoder {
	var isDecodingFromRiot: Bool {
		(userInfo[.isDecodingFromRiot] as? Bool) ?? false
	}
}

enum BaseURLs {
	static let auth = URL(string: "https://auth.riotgames.com")!
	static let authAPI = auth.appendingPathComponent("api/v1")
	static let entitlements = URL(string: "https://entitlements.auth.riotgames.com/api")!
	
	static func gameAPI(region: Region) -> URL {
		URL(string: "https://pd.\(region.subdomain).a.pvp.net")!
	}
	
	static func liveGameAPI(region: Region) -> URL {
		// TODO: test with other regions—just using the subdomain twice feels wrong…
		URL(string: "https://glz-\(region.subdomain)-1.\(region.subdomain).a.pvp.net")!
	}
}

private extension JSONDecoder.DateDecodingStrategy {
	static let iso8601OrTimestamp = custom { decoder in
		let container = try decoder.singleValueContainer()
		return try nil
			?? (try? Date(timeIntervalSince1970: container.decode(TimeInterval.self) / 1000))
			?? (try? formatter.date(from: container.decode(String.self)))
			??? DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Could not decode timestamp nor ISO-8601 date from value."
			)
	}
	
	private static let formatter = ISO8601DateFormatter()
}

import Foundation
import HandyOperators
import Protoquest

public final class ValorantClient: Identifiable {
	/// The decoder used to decode JSON data received from Riot's servers.
	public static let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
		$0.dateDecodingStrategy = .iso8601OrTimestamp
		$0.userInfo[.isDecodingFromRiot] = true
	}
	
	#if DEBUG
	/// A mocked client that's not actually signed in, for testing.
	public static let mocked = ValorantClient(
		client: .init(
			location: .europe,
			apiSession: .init(
				accessToken: .init(type: "", token: "", expiration: .distantFuture),
				entitlementsToken: "", sessionID: ""
			)
		),
		userID: .init()
	)
	#endif
	
	public let userID: User.ID
	public var location: Location { client.location }
	
	private let client: Client
	
	public convenience init(location: Location, session: APISession, urlSessionOverride: URLSession? = nil) throws {
		let userID = try session.accessToken.extractUserID()
		let client = Client(location: location, apiSession: session, sessionOverride: urlSessionOverride)
		self.init(client: client, userID: userID)
	}
	
	#if DEBUG
	// for testing
	convenience init(location: Location, session: APISession, userID: User.ID, urlSessionOverride: URLSession) {
		self.init(
			client: .init(
				location: location,
				apiSession: session,
				version: nil,
				sessionOverride: urlSessionOverride
			),
			userID: userID
		)
	}
	#endif
	
	private init(client: Client, userID: User.ID) {
		self.client = client
		self.userID = userID
	}
	
	func send<R: Request>(_ request: R) async throws -> R.Response {
		try await client.send(request)
	}
	
	public func setClientVersion(_ version: String) async {
		await client.setClientVersion(version)
	}
}

extension ValorantClient {
	public convenience init(from saved: SavedData) {
		self.init(
			client: .init(
				location: saved.location,
				apiSession: saved.session,
				version: saved.version
			),
			userID: saved.userID
		)
	}
	
	public func store() async -> SavedData {
		.init(
			session: await client.apiSession,
			location: client.location,
			version: await client.clientVersion,
			userID: userID
		)
	}
	
	public struct SavedData: Codable, Equatable {
		fileprivate var session: APISession
		fileprivate var location: Location
		fileprivate var version: String?
		fileprivate var userID: User.ID
	}
}

/// How Riot's API represents an error it encountered.
public struct RiotError: Decodable {
	/// A programmer-facing representation of the error that occurred, in `SCREAMING_SNAKE_CASE`.
	public var errorCode: String
	/// A human-readable description of the error.
	public var message: String
}

private final actor Client: Identifiable, Protoclient {
	typealias APIError = ValorantClient.APIError
	
	let requestEncoder = JSONEncoder() <- {
		$0.keyEncodingStrategy = .convertToSnakeCase
	}
	
	let responseDecoder = ValorantClient.responseDecoder
	
	let location: Location
	let session: URLSession
	
	private(set) var apiSession: APISession
	private(set) var clientVersion: String?
	
	let baseURL: URL
	
	func setClientVersion(_ version: String) {
		self.clientVersion = version
	}
	
	init(
		location: Location,
		apiSession: APISession,
		version: String? = nil,
		sessionOverride: URLSession? = nil
	) {
		self.location = location
		self.apiSession = apiSession
		self.clientVersion = version
		self.baseURL = BaseURLs.gameAPI(location: location)
		self.session = sessionOverride ?? .init(configuration: .ephemeral)
	}
	
	private static let encodedPlatformInfo = try! JSONEncoder()
		.encode(PlatformInfo.supportedExample)
		.base64EncodedString()
	
	func addHeaders(to rawRequest: inout URLRequest) async throws {
		if apiSession.accessToken.hasExpired {
			let id = UUID()
			if isResumingSession {
				print(id, "waiting for resumption…")
				try await withCheckedThrowingContinuation {
					waitingForSession.append($0)
				}
				print(id, "waiting complete!")
			} else {
				print(id, "resuming session")
				try await refreshAccessToken()
				print(id, "session resumed!")
			}
		}
		
		rawRequest.headers.authorization = apiSession.accessToken.encoded
		rawRequest.headers.entitlementsToken = apiSession.entitlementsToken
		rawRequest.headers.clientVersion = clientVersion
		rawRequest.headers.clientPlatform = Self.encodedPlatformInfo
	}
	
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) async throws -> Protoresponse {
		let (data, rawResponse) = try await session.data(for: rawRequest)
		let response = wrapResponse(data: data, response: rawResponse)
		
		let code = response.httpMetadata!.statusCode
		guard code == 200 else {
			throw APIError(statusCode: code, response: response)
		}
		
		return response
	}
	
	private var isResumingSession = false
	private var waitingForSession: [CheckedContinuation<Void, Error>] = []
	
	private func refreshAccessToken() async throws {
		assert(!isResumingSession)
		isResumingSession = true
		defer {
			isResumingSession = false
			waitingForSession = []
		}
		
		do {
			// for some reason swift forbids in-place mutation for isolated properties
			apiSession = try await apiSession <- { try await $0.refreshAccessToken() }
			
			waitingForSession.forEach { $0.resume() }
		} catch {
			waitingForSession.forEach { $0.resume(throwing: error) }
			throw APIError.sessionResumptionFailure(error)
		}
	}
	
	#if DEBUG
	nonisolated func traceOutgoing<R>(_ rawRequest: URLRequest, for request: R) where R : Request {
		print("\(request.path): sending \(rawRequest.httpMethod!) request to", rawRequest.url!)
		print(String(data: rawRequest.httpBody ?? Data(), encoding: .utf8)!)
	}
	
	nonisolated func traceIncoming<R>(_ response: Protoresponse, for request: R) where R : Request {
		print("\(request.path): received response:")
		if response.body.count < 1000 {
			print((try? response.decodeString(using: .utf8)) ?? "<undecodable>")
		} else {
			print("<\(response.body.count) bytes>")
		}
	}
	#endif
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
	static let entitlementsAPI = URL(string: "https://entitlements.auth.riotgames.com/api")!
	
	static func gameAPI(location: Location) -> URL {
		URL(string: "https://pd.\(location.shard).a.pvp.net")!
	}
	
	static func liveGameAPI(location: Location) -> URL {
		URL(string: "https://glz-\(location.region)-1.\(location.shard).a.pvp.net")!
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

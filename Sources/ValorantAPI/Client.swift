import Foundation
import Combine
import HandyOperators
import Protoquest

public final class ValorantClient: Identifiable {
	/// The decoder used to decode JSON data received from Riot's servers.
	public static let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
		$0.dateDecodingStrategy = .iso8601OrTimestamp
		$0.userInfo[.isDecodingFromRiot] = true
	}
	
	/// There's no real point for typed errors most of the time.
	public typealias BasicPublisher<T> = AnyPublisher<T, Error>
	
	/// Attempts to authenticate with the given credentials and, as a result, publishes a client instance initialized with the necessary tokens.
	public static func authenticated(username: String, password: String, region: Region) -> BasicPublisher<ValorantClient> {
		Client.authenticated(username: username, password: password, region: region)
			.map(Self.init(client:))
			.eraseToAnyPublisher()
	}
	
	private let client: Protoclient
	
	private init(client: Protoclient) {
		self.client = client
	}
	
	func send<R: Request>(_ request: R) -> BasicPublisher<R.Response> {
		client.send(request)
	}
}

private final class Client: Identifiable, Protoclient {
	static let requestEncoder = JSONEncoder() <- {
		$0.keyEncodingStrategy = .convertToSnakeCase
	}
	var requestEncoder: JSONEncoder { Self.requestEncoder }
	
	var responseDecoder: JSONDecoder { ValorantClient.responseDecoder }
	
	let region: Region
	let session = URLSession(configuration: .ephemeral)
	
	fileprivate var accessToken: String?
	fileprivate var entitlementsToken: String?
	
	var baseURL: URL { BaseURLs.gameAPI(region: region) }
	
	static func authenticated(username: String, password: String, region: Region) -> AnyPublisher<Client, Error> {
		let client = Client(region: region)
		return client.establishSession()
			.flatMap {
				client.getAccessToken(username: username, password: password)
					.map { client.accessToken = $0 }
			}
			.flatMap {
				client.getEntitlementsToken()
					.map { client.entitlementsToken = $0 }
			}
			.map { client }
			.eraseToAnyPublisher()
	}
	
	private init(region: Region) {
		self.region = region
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
		rawRequest.setValue(Self.encodedPlatformInfo, forHTTPHeaderField: "X-Riot-ClientPlatform")
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

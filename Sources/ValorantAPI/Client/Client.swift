import Foundation
import HandyOperators
import Protoquest
import Combine

public struct ValorantClient {
	private static let encodedPlatformInfo = try! JSONEncoder()
		.encode(PlatformInfo.supportedExample)
		.base64EncodedString()
	
	#if DEBUG
	/// A mocked client that's not actually signed in, for testing.
	public static let mocked = ValorantClient(session: .mocked)
	#endif
	
	/// The region/location this client makes requests in. Sessions are valid for all locations.
	public var location: Location
	/// The client version is required for many requests. A good third-party source of it would be https://valorant-api.com/v1/version
	public var clientVersion: String?
	
	/// The ID of the user owning this client's session.
	public let userID: User.ID
	
	private let clientStack: Protolayer
	private let sessionHandler: SessionHandler
	private let logger = Logger()
	
	public init(
		session: APISession,
		urlSessionOverride: URLSession? = nil,
		multifactorHandler: MultifactorHandler? = nil
	) {
		self.userID = session.userID
		self.location = session.location
		
		self.sessionHandler = .init(session: session, multifactorHandler: multifactorHandler)
		
		self.clientStack = Protolayer
			.urlSession(urlSessionOverride ?? .init(configuration: .ephemeral))
#if DEBUG
			.printExchanges()
#endif
			.readExchange { [logger] request, result in
				await logger.log(request: request, result: result)
			}
			.transformRequest { [sessionHandler] in
				$0.headers.authorization = try await sessionHandler.getAccessToken().encoded
				$0.headers.entitlementsToken = await sessionHandler.session.entitlementsToken
			}
	}
	
	/// Calls the given callback whenever the session is updated, e.g. when it has expired and is resumed or restarted.
	public func onSessionUpdate(call handle: @escaping ((APISession) -> Void)) -> AnyCancellable {
		sessionHandler.sessionSubject.sink(receiveValue: handle)
	}
	
	func send<R: ValorantRequest>(_ request: R) async throws -> R.Response {
		let urlRequest = try request.urlRequest(for: location) <- {
			$0.headers.clientVersion = clientVersion
			$0.headers.clientPlatform = Self.encodedPlatformInfo
		}
		
		let response = try await clientStack.send(urlRequest)
		
		let code = response.httpMetadata!.statusCode
		guard code == 200 else {
			throw APIError(statusCode: code, response: response)
		}
		
		return try request.decodeResponse(from: response)
	}
	
	/// Returns the current session.
	public func getSession() async -> APISession {
		await sessionHandler.session
	}
	
	/// Returns a log containing the last few exchanges with the server.
	public func getLog() async -> ClientLog {
		await logger.log
	}
	
	/// Creates a different version of this client for making requests in ``location``.
	/// This is a cheap operation; the heavyweight objects are reference types and shared with the new instance.
	public func `in`(_ location: Location) -> Self {
		self <- { $0.location = location }
	}
}

private final actor Logger {
	var log = ClientLog()
	
	func log(request: URLRequest, result: Protoresult) {
		log.logExchange(request: request, result: result)
	}
}

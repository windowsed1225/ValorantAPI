import Foundation
import Protoquest
import HandyOperators

final actor AuthClient: Protoclient {
	let baseURL = BaseURLs.authAPI
	let session: URLSession
	var accessToken: AccessToken?
	
	var sessionID: String? {
		session.configuration.httpCookieStorage!.cookies!
			.first { $0.name == "ssid" }?.value
	}
	
	init(sessionID: String? = nil, sessionOverride: URLSession? = nil) {
		self.session = sessionOverride ?? .init(
			configuration: .ephemeral,
			delegate: NoRedirectsDelegate.shared,
			delegateQueue: nil
		)
		let cookies = session.configuration.httpCookieStorage!
		if let sessionID = sessionID {
			cookies.setCookie(.init(properties: [
				.name: "ssid",
				.value: sessionID,
				.path: "/",
				.domain: "auth.riotgames.com",
			])!)
		}
	}
	
	let requestEncoder = JSONEncoder() <- {
		$0.keyEncodingStrategy = .convertToSnakeCase
	}
	let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
	}
	
	func setAccessToken(_ token: AccessToken) {
		self.accessToken = token
	}
	
	func addHeaders(to rawRequest: inout URLRequest) async {
		rawRequest.headers.authorization = accessToken?.encoded
	}
	
	private final class NoRedirectsDelegate: NSObject, URLSessionTaskDelegate {
		static let shared = NoRedirectsDelegate()
		
		func urlSession(
			_ session: URLSession,
			task: URLSessionTask,
			willPerformHTTPRedirection response: HTTPURLResponse,
			newRequest request: URLRequest
		) async -> URLRequest? {
			nil
		}
	}
}

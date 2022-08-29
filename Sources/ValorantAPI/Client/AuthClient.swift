import Foundation
import Protoquest
import HandyOperators

final actor AuthClient: Protoclient {
	let baseURL = BaseURLs.authAPI
	let urlSession: URLSession
	var accessToken: AccessToken?
	
	init(urlSessionOverride: URLSession? = nil) async {
		self.urlSession = urlSessionOverride ?? .init(
			configuration: .ephemeral,
			delegate: NoRedirectsDelegate.shared,
			delegateQueue: nil
		)
	}
	
	func cookies() -> [HTTPCookie] {
		urlSession.configuration.httpCookieStorage!.cookies ?? []
	}
	
	func setCookies(_ cookies: [HTTPCookie]) {
		cookies.forEach(urlSession.configuration.httpCookieStorage!.setCookie(_:))
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

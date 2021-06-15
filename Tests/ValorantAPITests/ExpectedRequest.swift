import Foundation
import HandyOperators

/// Describes an expectation of a request that the client should make along with its mocked response.
struct ExpectedRequest {
	let url: URL
	
	var method = "GET"
	var responseCode = 200
	var responseBody: Data?
	
	init(to url: URL) {
		self.url = url
	}
	
	init(to url: String) {
		self.init(to: URL(string: url)!)
	}
	
	func method(_ method: String) -> Self {
		self <- { $0.method = method }
	}
	
	func post() -> Self { method("POST") }
	
	func put() -> Self { method("PUT") }
	
	func responseCode(_ code: Int) -> Self {
		self <- { $0.responseCode = code }
	}
	
	func responseBody(_ body: Data) -> Self {
		self <- { $0.responseBody = body }
	}
	
	func responseBody(_ body: String) -> Self {
		responseBody(body.data(using: .utf8)!)
	}
	
	func responseBody(fileNamed filename: String) -> Self {
		let url = Bundle.module.url(forResource: "examples/\(filename)", withExtension: "json")!
		return responseBody(try! Data(contentsOf: url))
	}
}

import Foundation
import Protoquest
import Collections

public struct ClientLog {
	public let maxCount: Int
	public private(set) var exchanges: Deque<Exchange> = []
	
	public init(maxCount: Int = 50) {
		self.maxCount = maxCount
	}
	
	public mutating func logExchange(request: URLRequest, response: Protoresponse) {
		if exchanges.count >= maxCount {
			exchanges.removeFirst()
		}
		exchanges.append(.init(request: request, response: response))
	}
	
	public struct Exchange: Identifiable {
		public var id = ObjectID<Self, UUID>(rawID: .init())
		public var time = Date.now
		public var request: URLRequest
		public var response: Protoresponse
	}
}

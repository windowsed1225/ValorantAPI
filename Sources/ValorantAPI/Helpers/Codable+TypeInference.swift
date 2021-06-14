import Foundation

extension KeyedDecodingContainer {
	func decodeValue<T>(forKey key: K) throws -> T where T: Decodable {
		try decode(T.self, forKey: key)
	}
	
	func decodeValueIfPresent<T>(forKey key: K) throws -> T? where T: Decodable {
		try decodeIfPresent(T.self, forKey: key)
	}
}

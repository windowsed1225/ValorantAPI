import Foundation
import HandyOperators

/**
`Codable` interprets dictionaries with keys other than `String`s or `Int`s as arrays of alternating keys and values instead of dictionaries, even if the keys would just encode to strings anyway.

This wrapper lets us work around that by providing its custom decoding logic using the protocol `StringConvertible` to represent keys as strings.
*/
@propertyWrapper
public struct _StringKeyedDictionary<Key: LosslessStringConvertible & Hashable, Value> {
	public var wrappedValue: [Key: Value]
	
	public init(wrappedValue: [Key: Value]) {
		self.wrappedValue = wrappedValue
	}
}

extension _StringKeyedDictionary: Codable where Value: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawKeyedDictionary = try container.decode([String: Value].self)
		let entries = try rawKeyedDictionary.lazy.map { rawKey, value in (
			try Key(rawKey) ??? DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Could not create '\(Key.self)' from invalid string '\(rawKey)'."
			),
			value
		)}
		
		wrappedValue = .init(uniqueKeysWithValues: entries)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		let rawKeyedDictionary = Dictionary(uniqueKeysWithValues: wrappedValue.map { ($0.description, $1) })
		try container.encode(rawKeyedDictionary)
	}
}

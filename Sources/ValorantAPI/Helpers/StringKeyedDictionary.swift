import Foundation
import HandyOperators

/**
`Codable` interprets dictionaries with keys other than `String`s or `Int`s as arrays of alternating keys and values instead of dictionaries, even if the keys would just encode to strings anyway.

This wrapper lets us work around that by providing its custom decoding logic using the protocol `StringConvertible` to represent keys as strings.
*/
@propertyWrapper
struct StringKeyedDictionary<Key: StringConvertible & Hashable, Value> {
	var wrappedValue: [Key: Value]
	
	init(wrappedValue: [Key: Value]) {
		self.wrappedValue = wrappedValue
	}
}

extension StringKeyedDictionary: Codable where Value: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawKeyedDictionary = try container.decode([String: Value].self)
		
		wrappedValue = .init(
			uniqueKeysWithValues: try rawKeyedDictionary
				.map { rawKey, value in
					try (
						Key(stringValue: rawKey) ??? DecodingError.dataCorruptedError(
							in: container,
							debugDescription: "Could not create '\(Key.self)' from invalid string '\(rawKey)'."
						),
						value
					)
				}
		)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		let rawKeyedDictionary = Dictionary(uniqueKeysWithValues: wrappedValue.map { ($0.stringValue, $1) })
		try container.encode(rawKeyedDictionary)
	}
}

protocol StringConvertible {
	var stringValue: String { get }
	
	init?(stringValue: String)
}

extension UUID: StringConvertible {
	var stringValue: String { uuidString }
	
	init?(stringValue: String) {
		self.init(uuidString: stringValue)
	}
}

extension String: StringConvertible {
	var stringValue: String { self }
	
	init?(stringValue: String) {
		self = stringValue
	}
}

extension ObjectID: StringConvertible where RawValue: StringConvertible {
	var stringValue: String { rawValue.stringValue }
	
	init?(stringValue: String) {
		guard let raw = RawValue(stringValue: stringValue) else { return nil }
		self.init(raw)
	}
}

import Foundation

@propertyWrapper
public struct SpecialOptional<Strategy: SpecialOptionalStrategy, Value: Codable>: Codable where Strategy.Value: Codable {
	public var wrappedValue: Value?
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let isNil = try container.decodeNil() // for compatibility with re-encoding
			|| Strategy.isNil(container.decode(Strategy.Value.self))
		wrappedValue = isNil ? nil : try container.decode(Value.self)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(wrappedValue)
	}
	
	public init(strategy: Strategy.Type = Strategy.self, wrappedValue: Value? = nil) {
		self.wrappedValue = wrappedValue
	}
	
	public init(_ strategy: Strategy, wrappedValue: Value? = nil) {
		self.wrappedValue = wrappedValue
	}
}

public protocol SpecialOptionalStrategy {
	associatedtype Value
	
	static func isNil(_ value: Value) -> Bool
}

public struct EmptyStringOptionalStrategy: SpecialOptionalStrategy {
	public static func isNil(_ value: String) -> Bool {
		value.isEmpty
	}
}

extension SpecialOptionalStrategy where Self == EmptyStringOptionalStrategy {
	static var emptyString: Self { .init() }
}

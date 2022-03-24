import Foundation

public struct LowercaseUUID: Hashable, Codable, LosslessStringConvertible, RawRepresentable, CodingKeyRepresentable {
	var uuid: UUID
	
	public var rawValue: String { description }
	
	public var description: String {
		uuid.uuidString.lowercased()
	}
	
	init(_ uuid: UUID) {
		self.uuid = uuid
	}
	
	init() {
		self.init(UUID())
	}
	
	public init?(_ description: String) {
		assert(description.lowercased() == description)
		guard let uuid = UUID(uuidString: description) else { return nil }
		self.init(uuid)
	}
	
	public init?(rawValue: String) {
		self.init(rawValue)
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.init(try container.decode(UUID.self))
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(description)
	}
}

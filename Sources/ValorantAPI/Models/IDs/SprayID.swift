import Foundation

public enum Spray {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	
	public enum Slot {
		public typealias ID = ObjectID<Self, LowercaseUUID>
	}
}

public extension Spray.Slot.ID {
	static let preRound = Self("0814b2fe-4512-60a4-5288-1fbdcec6ca48")!
	static let midRound = Self("04af080a-4071-487b-61c0-5b9c0cfaac74")!
	static let postRound = Self("5863985e-43ac-b05d-cb2d-139e72970014")!
	
	/// all three spray slots in order (pre-, mid-, post-round)
	static let inOrder = [preRound, midRound, postRound]
	
	var name: String {
		switch self {
		case .preRound:
			return "pre-round"
		case .midRound:
			return "mid-round"
		case .postRound:
			return "post-round"
		default:
			return "slot"
		}
	}
}

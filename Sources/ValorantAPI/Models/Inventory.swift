import Foundation

public struct Inventory: Codable {
	public static let starterAgents: Set<Agent.ID> = [.jett, .phoenix, .sova, .brimstone, .sage]
	
	public var agents: Set<Agent.ID>
	public var agentsIncludingStarters: Set<Agent.ID>
	public var cards: Set<PlayerCard.ID>
	public var titles: Set<PlayerTitle.ID>
	
	public init(_ raw: APIInventory) {
		let collections = Dictionary(
			uniqueKeysWithValues: raw.collectionsByType
				.map { ($0.id, $0) }
		)
		
		func collectItems<ID>(_ type: ItemCollection.ID) -> Set<ID>
		where ID: ObjectIDProtocol, ID.RawID == LowercaseUUID {
			Set(collections[type]!.items.map(\.id).map(ID.init(rawID:)))
		}
		
		agents = collectItems(.agents)
		cards = collectItems(.cards)
		titles = collectItems(.titles)
		
		assert(agents.intersection(Self.starterAgents).isEmpty)
		agentsIncludingStarters = agents.union(Self.starterAgents)
	}
}

private extension ItemCollection.ID {
	static let agents = Self("01bb38e1-da47-4e6a-9b3d-945fe4655707")!
	static let cards = Self("3f296c07-64c3-494c-923b-fe692a4fa1bd")!
	static let titles = Self("de7caa6b-adf7-4588-bbd1-143831e786c6")!
}

/// The way the API describes the player inventory, which is really general and really impractical. You're probably looking for ``Inventory``.
public struct APIInventory: Decodable {
	fileprivate var collectionsByType: [ItemCollection]
	
	private enum CodingKeys: String, CodingKey {
		case collectionsByType = "EntitlementsByTypes"
	}
}

private struct ItemCollection: Decodable {
	typealias ID = ObjectID<Self, LowercaseUUID>
	
	var id: ID
	var items: [Item]
	
	private enum CodingKeys: String, CodingKey {
		case id = "ItemTypeID"
		case items = "Entitlements"
	}
}

private struct Item: Decodable {
	var typeID: LowercaseUUID
	var id: LowercaseUUID
	
	private enum CodingKeys: String, CodingKey {
		case typeID = "TypeID"
		case id = "ItemID"
	}
}

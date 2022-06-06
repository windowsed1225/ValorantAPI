import Foundation

public struct Inventory: Codable {
	public static let starterAgents: Set<Agent.ID> = [.jett, .phoenix, .sova, .brimstone, .sage]
	
	public var agents: Set<Agent.ID>
	public var agentsIncludingStarters: Set<Agent.ID>
	public var cards: Set<PlayerCard.ID>
	public var titles: Set<PlayerTitle.ID>
	public var skinLevels: Set<Weapon.Skin.Level.ID>
	public var skinChromas: Set<Weapon.Skin.Chroma.ID>
	public var sprays: Set<Spray.ID>
	public var contracts: Set<Contract.ID>
	public var charms: [Weapon.Charm.ID: [Weapon.Charm.Instance.ID]]
	
	init(_ raw: APIInventory) {
		let collections = Dictionary(
			uniqueKeysWithValues: raw.collectionsByType
				.map { ($0.id, $0) }
		)
		
		func collectItems<ID>(_ type: ItemCollection.ID) -> Set<ID>
		where ID: ObjectIDProtocol, ID.RawID == LowercaseUUID {
			Set(collections[type]?.items.lazy.map(\.id).map(ID.init(rawID:)) ?? [])
		}
		
		agents = collectItems(.agents)
		cards = collectItems(.cards)
		titles = collectItems(.titles)
		skinLevels = collectItems(.skinLevels)
		skinChromas = collectItems(.skinChromas)
		sprays = collectItems(.sprays)
		contracts = collectItems(.contracts)
		charms = collections[.charms]?.items.lazy.map(Charm.init)
			.reduce(into: [:]) { $0[$1.charm, default: []].append($1.instance) }
			?? [:]
		
		assert(agents.intersection(Self.starterAgents).isEmpty)
		agentsIncludingStarters = agents.union(Self.starterAgents)
	}
	
	private struct Charm {
		var charm: Weapon.Charm.ID
		var instance: Weapon.Charm.Instance.ID
		
		init(_ item: Item) {
			charm = .init(rawID: item.id)
			instance = .init(rawID: item.instanceID!)
		}
	}
}

private extension ItemCollection.ID {
	static let agents = Self("01bb38e1-da47-4e6a-9b3d-945fe4655707")!
	static let cards = Self("3f296c07-64c3-494c-923b-fe692a4fa1bd")!
	static let titles = Self("de7caa6b-adf7-4588-bbd1-143831e786c6")!
	static let skinLevels = Self("e7c63390-eda7-46e0-bb7a-a6abdacd2433")!
	static let skinChromas = Self("3ad1b2b2-acdb-4524-852f-954a76ddae0a")!
	static let sprays = Self("d5f120f8-ff8c-4aac-92ea-f2b5acbe9475")!
	static let contracts = Self("f85cb6f7-33e5-4dc8-b609-ec7212301948")!
	static let charms = Self("dd3bf334-87f3-40bd-b043-682a57a8dc3a")!
}

struct APIInventory: Decodable {
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
	var id: LowercaseUUID
	var instanceID: LowercaseUUID?
	
	private enum CodingKeys: String, CodingKey {
		case id = "ItemID"
		case instanceID = "InstanceID"
	}
}

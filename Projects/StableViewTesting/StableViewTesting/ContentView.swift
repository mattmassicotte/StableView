import SwiftUI
import StableView

let names = [
	"Aknot",
	"Aziz",
	"Billy",
	"Jean-Baptiste Emanuel Zorg",
	"Korben",
	"Leeloo",
	"Ruby Rhod",
	"Vito Cornelius",
]

struct Item : Hashable, Sendable {
	let name: String
	let date: Date
	
	static func random(startUnixtime: Int = 0) -> Item {
		let now = Int(Date.now.timeIntervalSince1970)
		
		precondition(startUnixtime >= 0)
		precondition(startUnixtime <= now)
		
		let interval = startUnixtime..<now
		let value = Double(interval.randomElement()!)
		
		return Item(
			name: names.randomElement()!,
			date: Date(timeIntervalSince1970: value)
		)
	}
}

extension Item : Comparable {
	static func < (lhs: Item, rhs: Item) -> Bool {
		if lhs.date != rhs.date {
			return lhs.date < rhs.date
		}
		
		return lhs.name < rhs.name
	}
}

struct ContentView : View {
	@State var items: [Item] = []
	
    var body: some View {
		VStack {
			PositionPreservingList(items: items) { item in
				VStack(alignment: .leading) {
					Text(item.name)
						.font(.title3)
					Text(item.date.description)
						.font(.caption)
				}
			}
			.refreshable {
				await reload(allNew: false)
			}
			
			HStack {
				Button("Clear") {
					self.items.removeAll()
				}
				Button("All New") {
					Task { await reload(allNew: true) }
				}
				Button("Some New") {
					Task { await reload(allNew: false) }
				}
			}
		}
		.task {
			await reload(allNew: true)
		}
		.padding()
    }
	
	private func reload(allNew: Bool) async {
		let count = (1..<5).randomElement()!
		let oldestUnixtime = 0
		let newestUnixtime = Int(items.first?.date.timeIntervalSince1970 ?? 0.0)
		let probabilityOfNew = allNew ? 9 : 7
		
		for _ in 0..<count {
			let new = (probabilityOfNew..<10).randomElement()! >= 7
			let startTime = new ? newestUnixtime : oldestUnixtime
			
			let item = Item.random(startUnixtime: startTime)
			
			self.items.append(item)
		}
		
		self.items.sort(by: >)
	}
}

#Preview {
    ContentView()
}

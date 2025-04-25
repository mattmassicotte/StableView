import Testing
import SwiftUI

import StableView

struct StableViewTests {
	@Test func exampleCode() throws {
		struct AnchoredView: View {
			let items = ["one", "two", "three"]
			@State private var position: AnchoredListPosition<String>? = AnchoredListPosition(item: "two")

			public var body: some View {
			   AnchoredList(items: items, position: $position) { item, row in
				   Text("item: \(item)")
			   }
			}
		}
	}
}

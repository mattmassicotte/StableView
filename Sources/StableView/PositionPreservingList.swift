import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum ScrollState<Item: Hashable & Sendable> {
	case anchor(Item, offset: CGFloat)
	case absolute(CGFloat)
}

extension ScrollState : Equatable where Item : Equatable {}
extension ScrollState : Hashable where Item : Hashable {}

public struct PositionPreservingList<Content: View, Item: Hashable & Sendable> {
	public typealias ViewControllerType = TableViewController<Content, Item>
	
	@Environment(\.refresh) private var refreshAction
	@Binding var scrollState: ScrollState<Item>
	
	private let items: [Item]
	private let content: (Item, Int) -> Content
	
	public init(
		items: [Item],
		scrollState: Binding<ScrollState<Item>>,
		@ViewBuilder content: @escaping (Item, Int) -> Content
	) {
		self.items = items
		self._scrollState = scrollState
		self.content = content
	}
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension PositionPreservingList : NSViewControllerRepresentable {
	public typealias NSViewControllerType = ViewControllerType
	
	public func makeNSViewController(context: Context) -> NSViewControllerType {
		TableViewController(items: items, content: content)
	}
	
	public func updateNSViewController(_ viewController: NSViewControllerType, context: Context) {
		viewController.items = items
		viewController.refreshAction = refreshAction
	}
}
#elseif canImport(UIKit)
extension PositionPreservingList : UIViewControllerRepresentable {
	public typealias UIViewControllerType = ViewControllerType
	
	public func makeUIViewController(context: Context) -> UIViewControllerType {
		TableViewController(items: items, content: content)
	}
	
	public func updateUIViewController(_ viewController: UIViewControllerType, context: Context) {
		viewController.items = items
		viewController.refreshAction = refreshAction
		viewController.scrollStateHandler = { state in
			DispatchQueue.main.async {
				scrollState = state
			}
		}
	}
}

#endif

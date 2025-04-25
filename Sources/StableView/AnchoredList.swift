import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public struct AnchoredListPosition<Item: Hashable & Sendable> {
	public let item: Item
	public let offset: CGFloat
	
	public init(item: Item, offset: CGFloat = 0.0) {
		self.item = item
		self.offset = offset
	}
}

extension AnchoredListPosition : Equatable where Item : Equatable {}
extension AnchoredListPosition : Hashable where Item : Hashable {}
extension AnchoredListPosition : Sendable where Item : Sendable {}

@MainActor
public struct AnchoredList<Content: View, Item: Hashable & Sendable> {
	public typealias ViewControllerType = TableViewController<Content, Item>
	public typealias Position = AnchoredListPosition<Item>
	
	@Environment(\.refresh) private var refreshAction
	@Binding private var scrollState: Position?
	
	private let items: [Item]
	private let content: (Item, Int) -> Content
	var fallbackToTop: Bool = true
	
	public init(
		items: [Item],
		position: Binding<Position?>,
		@ViewBuilder content: @escaping (Item, Int) -> Content
	) {
		self.items = items
		self._scrollState = position
		self.content = content
	}
	
	private func updateViewController(_ viewController: ViewControllerType, context: Context) {
		viewController.items = items
		viewController.refreshAction = refreshAction
		viewController.positionChangedHandler = { state in
			DispatchQueue.main.async {
				scrollState = state
			}
		}
	}
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension AnchoredList : NSViewControllerRepresentable {
	public typealias NSViewControllerType = ViewControllerType
	
	public func makeNSViewController(context: Context) -> NSViewControllerType {
		TableViewController(items: items, content: content)
	}
	
	public func updateNSViewController(_ viewController: NSViewControllerType, context: Context) {
		updateViewController(viewController, context: context)
	}
}
#elseif canImport(UIKit)
extension AnchoredList : UIViewControllerRepresentable {
	public typealias UIViewControllerType = ViewControllerType
	
	public func makeUIViewController(context: Context) -> UIViewControllerType {
		TableViewController(items: items, content: content)
	}
	
	public func updateUIViewController(_ viewController: UIViewControllerType, context: Context) {
		updateViewController(viewController, context: context)
	}
}
#endif

//extension AnchoredList {
//	@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, tvOS 18.0, visionOS 2.0, *)
//	public func expectedScrollingDirection(_ direction: VerticalDirection) -> Self {
//		expectedScrollingDirection(up: direction == .up)
//	}
//	
//	public func expectedScrollingDirection(up: Bool) -> Self {
//		var view = self
//		
//		view.fallbackToTop = up
//		
//		return view
//	}
//}

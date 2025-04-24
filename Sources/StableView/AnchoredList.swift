import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum AnchoredListPosition<Item: Hashable & Sendable> {
	case item(Item, offset: CGFloat)
	case absolute(CGFloat)
}

extension AnchoredListPosition : Equatable where Item : Equatable {}
extension AnchoredListPosition : Hashable where Item : Hashable {}

public struct AnchoredList<Content: View, Item: Hashable & Sendable> {
	public typealias ViewControllerType = TableViewController<Content, Item>
	
	@Environment(\.refresh) private var refreshAction
	@Binding private var scrollState: AnchoredListPosition<Item>
	
	private let items: [Item]
	private let content: (Item, Int) -> Content
	var fallbackToTop: Bool = true
	
	public init(
		items: [Item],
		scrollState: Binding<AnchoredListPosition<Item>>,
		@ViewBuilder content: @escaping (Item, Int) -> Content
	) {
		self.items = items
		self._scrollState = scrollState
		self.content = content
	}
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension AnchoredList : NSViewControllerRepresentable {
	public typealias NSViewControllerType = ViewControllerType
	
	public func makeNSViewController(context: Context) -> NSViewControllerType {
		TableViewController(items: items, content: content)
	}
	
	public func updateNSViewController(_ viewController: NSViewControllerType, context: Context) {
		viewController.items = items
		viewController.refreshAction = refreshAction
		viewController.scrollStateHandler = { state in
			scrollState = state
		}
	}
}
#elseif canImport(UIKit)
extension AnchoredList : UIViewControllerRepresentable {
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

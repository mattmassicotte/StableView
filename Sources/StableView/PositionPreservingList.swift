import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public struct PositionPreservingList<Content: View, Item: Hashable & Sendable> {
	@Environment(\.refresh) private var refreshAction
	
	private let items: [Item]
	private let content: (Item, Int) -> Content
	
	public init(
		items: [Item],
		@ViewBuilder content: @escaping (Item, Int) -> Content
	) {
		self.items = items
		self.content = content
	}
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension PositionPreservingList : NSViewControllerRepresentable {
	public typealias NSViewControllerType = TableViewController<Content, Item>
	
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
	public typealias UIViewControllerType = TableViewController<Content, Item>
	
	public func makeUIViewController(context: Context) -> UIViewControllerType {
		TableViewController(items: items, content: content)
	}
	
	public func updateUIViewController(_ viewController: UIViewControllerType, context: Context) {
		viewController.items = items
		viewController.refreshAction = refreshAction
	}
}

#endif

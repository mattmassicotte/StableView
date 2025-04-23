import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension TableView {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
	func dequeueHostingCell<Content: View>(identifier: String, content: () -> Content) -> NSView {
		let reusedView = self.makeView(withIdentifier: NSUserInterfaceItemIdentifier(identifier), owner: nil)
		let content = content()
		
		if let view = reusedView as? NSHostingView<Content> {
			view.rootView = content
			
			return view
		}
		
		let view = NSHostingView(rootView: content)
		
		view.translatesAutoresizingMaskIntoConstraints = false

		return view
	}
#else
	func dequeueHostingCell<Content: View>(identifier: String, content: () -> Content) -> UITableViewCell {
		let cell = dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell()
		let hostingConfig = UIHostingConfiguration(content: content)
		
		cell.contentConfiguration = hostingConfig
		
		return cell
	}
#endif
}

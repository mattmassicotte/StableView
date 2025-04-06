import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension TableView {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
	func dequeueHostingCell<Content: View>(identifier: String, content: () -> Content) -> NSView {
		NSHostingView(rootView: content())
	}
#else
	func dequeueHostingCell<Content: View>(identifier: String, content: () -> Content) -> UITableViewCell {
		let cell = dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell()
		
		cell.contentConfiguration = UIHostingConfiguration(content: content)
		
		return cell
	}
#endif
}

public final class TableViewController<Content: View, Item: Hashable & Sendable> : ViewController {
	enum Section {
		case main
	}
	
	struct ScrollState {
		let anchorItem: Item
		let offset: CGFloat
	}
	
	let tableView = TableView(frame: .zero)
	private let content: (Item, Int) -> Content
	var refreshAction: RefreshAction?
#if os(iOS) || os(visionOS)
	let refreshControl = UIRefreshControl()
#endif
	
	private lazy var dataSource: TableViewDiffableDataSource<Section, Item> = {
		TableViewDiffableDataSource<Section, Item>(tableView: tableView) { [content] tableView, path, item in
			return tableView.dequeueHostingCell(identifier: "id") {
				content(item, path.row)
			}
		}
	}()
	
	public init(
		items: [Item],
		@ViewBuilder content: @escaping (Item, Int) -> Content
	) {
		self.content = content
		
		super.init(nibName: nil, bundle: nil)
		
		self.items = items
		
#if os(iOS) || os(visionOS)
		tableView.refreshControl = refreshControl
		refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
#endif
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public var items: [Item] {
		get {
			dataSource.snapshot().itemIdentifiers
		}
		set {
			let state = currentScrollState
			
			var snapshot = dataSource.snapshot()
			
			snapshot.deleteAllItems()
			
			snapshot.appendSections([.main])
			snapshot.appendItems(newValue, toSection: .main)
			
			dataSource.apply(snapshot, animatingDifferences: false)
			
			if let state {
				setScrollState(to: state)
			}
		}
	}
	
	public override func loadView() {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
		let column = NSTableColumn(identifier: .init("main"))
		
		tableView.addTableColumn(column)
		tableView.usesAutomaticRowHeights = true
		tableView.headerView = nil
		
		let scrollView = NSScrollView()
		
		scrollView.documentView = tableView
		
		self.view = scrollView
#elseif canImport(UIKit)
		self.view = tableView
#endif
	}
	
#if os(iOS) || os(visionOS)
	@objc private func refresh(_ refreshControl: UIRefreshControl) {
		Task {
			await refreshAction?()
			
			refreshControl.endRefreshing()
		}
	}
#endif
}

extension TableViewController {
	private func scrollPosition(at path: IndexPath) -> CGFloat {
		let rect = tableView.rectForRow(at: path)
		
#if os(macOS)
		// the rows are inset by 10.0 within an NSTableView and I cannot figure out how to calculated this programmatically
		return rect.minY - 10.0
#else
		return rect.minY
#endif
	}
	
#if os(macOS)
	private var scrollView: NSScrollView {
		tableView.enclosingScrollView!
	}
#else
	private var scrollView: UIScrollView {
		tableView
	}
#endif
	
	private var scrollPosition: CGFloat {
		scrollView.contentOffset.y
	}
	
	var currentScrollState: ScrollState? {
		guard
			let indexPaths = tableView.indexPathsForVisibleRows,
			let topRowPath = indexPaths.first
		else {
			return nil
		}
		
		let item = items[topRowPath.row]
		
		let rowPosition = scrollPosition(at: topRowPath)
				
		let offset = scrollPosition - rowPosition
		print("get:", rowPosition, offset, topRowPath, item)
		
		return ScrollState(anchorItem: item, offset: offset)
	}
	
	func setScrollState(to state: ScrollState) {
		guard let index = dataSource.indexPath(for: state.anchorItem) else {
			return
		}
		
		let rowPosition = scrollPosition(at: index)
		
		let point = CGPoint(x: 0, y: rowPosition + state.offset)
		
		print("set:", rowPosition, state.offset, index, state.anchorItem)
		
		#if os(macOS)
		tableView.scroll(point)
		#else
		tableView.layoutIfNeeded()
		tableView.setContentOffset(point, animated: false)
		#endif
	}
}

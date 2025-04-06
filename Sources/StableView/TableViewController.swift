import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public typealias TableViewControllerDelegatingType = NSScrollViewDelegate
#elseif canImport(UIKit)
import UIKit

public typealias TableViewControllerDelegatingType = UITableViewDelegate
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

public final class TableViewController<Content: View, Item: Hashable & Sendable> : ViewController, TableViewControllerDelegatingType {
	enum Section {
		case main
	}
	
	let tableView = TableView(frame: .zero)
	private let content: (Item, Int) -> Content
	var refreshAction: RefreshAction?
#if os(iOS) || os(visionOS)
	let refreshControl = UIRefreshControl()
#endif
	var scrollStateHandler: ((ScrollState<Item>) -> Void)?
	
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
		
		tableView.delegate = self
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
			
			scrollStateHandler?(state)
			
			var snapshot = dataSource.snapshot()
			
			snapshot.deleteAllItems()
			
			snapshot.appendSections([.main])
			snapshot.appendItems(newValue, toSection: .main)
			
			dataSource.apply(snapshot, animatingDifferences: false)
			
			setScrollState(to: state)
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
		refreshControl.beginRefreshing()

		Task {
			await refreshAction?()
			
			refreshControl.endRefreshing()
		}
	}
#endif
	
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let state = currentScrollState
		
		scrollStateHandler?(state)
	}
	
	public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
		false
	}
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
	
	private var currentScrollState: ScrollState<Item> {
		guard
			let indexPaths = tableView.indexPathsForVisibleRows,
			let topRowPath = indexPaths.first
		else {
			return .absolute(0.0)
		}
		
		let item = items[topRowPath.row]
		
		let rowPosition = scrollPosition(at: topRowPath)
				
		let offset = scrollPosition - rowPosition
		
		return ScrollState.anchor(item, offset: offset)
	}
	
	private func setScrollState(to state: ScrollState<Item>) {
		let yPosition: CGFloat
		
		switch state {
		case let .absolute(pos):
			yPosition = pos
		case let .anchor(item, offset: offset):
			guard let index = dataSource.indexPath(for: item) else {
				return
			}
			
			yPosition = scrollPosition(at: index) + offset
		}
		
		let point = CGPoint(x: 0, y: yPosition)
		
#if os(macOS)
		tableView.scroll(point)
#else
		tableView.layoutIfNeeded()
		tableView.setContentOffset(point, animated: false)
#endif
	}
}

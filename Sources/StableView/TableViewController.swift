import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public protocol ScrollViewDelegate {
}

public typealias TableViewControllerDelegatingType = ScrollViewDelegate
#elseif canImport(UIKit)
import UIKit

public typealias TableViewControllerDelegatingType = UITableViewDelegate
#endif

public final class TableViewController<Content: View, Item: Hashable & Sendable> : ViewController, TableViewControllerDelegatingType {
	public typealias Position = AnchoredListPosition<Item>
	
	enum Section {
		case main
	}
	
	let tableView = TableView(frame: .zero)
	public var refreshAction: RefreshAction?
	public var expectsScrollingUp: Bool = true
#if os(iOS) || os(visionOS)
	let refreshControl = UIRefreshControl()
#else
#endif
	public var scrollStateHandler: ((AnchoredListPosition<Item>) -> Void)?
	private let dataSource: TableViewDiffableDataSource<Section, Item>
	private var layoutSize: CGSize = .zero
	private var scrollState: Position = .absolute(0.0) {
		didSet {
			scrollStateChanged()
		}
	}

	public init(
		items: [Item],
		@ViewBuilder content: @escaping (Item, Int) -> Content
	) {
		self.dataSource = TableViewDiffableDataSource<Section, Item>(tableView: tableView) { [content] tableView, path, item in
			tableView.dequeueHostingCell(identifier: "id") {
				content(item, path.row)
			}
		}
		
		super.init(nibName: nil, bundle: nil)
		
		self.items = items
		
#if os(iOS) || os(visionOS)
		tableView.refreshControl = refreshControl
		refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
		tableView.delegate = self
#endif
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	public var items: [Item] {
		get {
			dataSource.snapshot().itemIdentifiers
		}
		set {
			if newValue == items {
				return
			}
			
			withScrollStateMutation {
				var snapshot = dataSource.snapshot()
				
				snapshot.deleteAllItems()
				
				snapshot.appendSections([.main])
				snapshot.appendItems(newValue, toSection: .main)
				
				dataSource.apply(snapshot, animatingDifferences: false)
			}
		}
	}
	
	private func withScrollStateMutation(_ block: () -> Void) {
		let state = currentScrollState
		
		block()
		
		guard state != scrollState else { return }
		
		setScrollState(to: state)
	}
	
	public override func loadView() {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
		let column = NSTableColumn(identifier: .init("main"))
		
		tableView.addTableColumn(column)
		tableView.usesAutomaticRowHeights = true
		tableView.headerView = nil
		tableView.allowsColumnResizing = false 
		tableView.allowsEmptySelection = true
		tableView.allowsMultipleSelection = false
		
		let scrollView = NSScrollView()
		
		scrollView.hasVerticalScroller = true
		scrollView.hasHorizontalRuler = true
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(scrollContentBoundsDidChange(_:)),
			name: NSView.boundsDidChangeNotification,
			object: scrollView.contentView
		)

		
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
	
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		scrollPositionChanged()
	}
	
	public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
		false
	}
	
	public override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}
	
	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
//		print("layout: ", tableView.frame)
	}
#else
	@objc
	private func scrollContentBoundsDidChange(_ notification: Notification) {
		scrollPositionChanged()
	}
#endif
}

extension TableViewController {
	private func scrollPosition(at path	: IndexPath) -> CGFloat {
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
	
	private var bottomScrollPosition: CGFloat {
		let snapshot = dataSource.snapshot()
		
		guard
			let lastItem = snapshot.itemIdentifiers.last,
			let row = snapshot.indexOfItem(lastItem)
		else {
			return 0.0
		}
		
		let indexPath = IndexPath(row: row, section: 0)
		
		return scrollPosition(at: indexPath)
	}
}

extension TableViewController {
	private var currentScrollState: Position {
		guard
			let indexPaths = tableView.indexPathsForVisibleRows,
			let topRowPath = indexPaths.first,
			let bottomRowPath = indexPaths.last
		else {
			return .absolute(0.0)
		}
		
		let item = items[topRowPath.row]
		
		let rowPosition = scrollPosition(at: topRowPath)
				
		let offset = scrollPosition - rowPosition
		
		return Position.item(item, offset: offset)
	}
	
	private func setScrollState(to state: Position) {
		let yPosition: CGFloat
		
		switch state {
		case let .absolute(pos):
			yPosition = pos
		case let .item(item, offset: offset):
			if let index = dataSource.indexPath(for: item) {
				yPosition = scrollPosition(at: index) + offset
				break
			}
			
			// the current anchor is no longer in the table, so we have to pick a fallback
			yPosition = expectsScrollingUp ? bottomScrollPosition : 0.0
		}
		
		let point = CGPoint(x: 0, y: yPosition)
		
#if os(macOS)
		tableView.scroll(point)
#else
		tableView.layoutIfNeeded()
		tableView.setContentOffset(point, animated: false)
#endif
		
		scrollState = state
	}
}

extension TableViewController {
	private func scrollPositionChanged() {
		self.scrollState = currentScrollState
	}
	
	private func tableLayoutChanged() {
	}
	
	private func withContentMutation(_ block: () -> Void) {
		block()
	}
	
	private func scrollStateChanged() {
		scrollStateHandler?(scrollState)
	}
}

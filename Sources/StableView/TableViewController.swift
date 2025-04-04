import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public final class TableViewController<Content: View, Item: Hashable & Sendable> : ViewController {
	enum Section {
		case main
	}
	
	let tableView = TableView(frame: .zero)
	private let content: (Item) -> Content
	var refreshAction: RefreshAction?
#if os(iOS) || os(visionOS)
	let refreshControl = UIRefreshControl()
#endif
	
	private lazy var dataSource: TableViewDiffableDataSource<Section, Item> = {
		TableViewDiffableDataSource<Section, Item>(tableView: tableView) { [content] tableView, path, item in
			tableView.dequeueHostingCell(identifier: "id") {
				content(item)
			}
		}
	}()
	
	public init(
		items: [Item],
		@ViewBuilder content: @escaping (Item) -> Content
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
			var snapshot = dataSource.snapshot()
			
			snapshot.deleteAllItems()
			
			snapshot.appendSections([.main])
			snapshot.appendItems(newValue, toSection: .main)
			
			dataSource.apply(snapshot, animatingDifferences: true)
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
		}
	}
#endif
}

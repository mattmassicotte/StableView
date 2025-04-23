import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

typealias TableViewDiffableDataSource = NSTableViewDiffableDataSource
public typealias ViewController = NSViewController
typealias TableView = NSTableView
typealias ScrollView = NSScrollView

extension TableViewDiffableDataSource {
	convenience init(
		tableView: NSTableView,
		cellProvider: @escaping (NSTableView, IndexPath, ItemIdentifierType) -> NSView
	) {
		self.init(tableView: tableView) { tableView, _, row, item in
			cellProvider(tableView, IndexPath(item: row, section: 0), item)
		}
	}
	
	func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
		guard let row = row(forItemIdentifier: itemIdentifier) else {
			return nil
		}
		
		return IndexPath(item: row, section: 0)
	}
}

extension TableView {	
	var indexPathsForVisibleRows: [IndexPath]? {
		let rows = rows(in: visibleRect)
		
		return (rows.lowerBound..<rows.upperBound).map { i in
			IndexPath(arrayLiteral: 0, i)
		}
	}
	
	func rectForRow(at indexPath: IndexPath) -> CGRect {
		rect(ofRow: indexPath.row)
	}
}

extension IndexPath {
	var row: Int {
		item
	}
	
	init(row: Int, section: Int) {
		self.init(item: row, section: section)
	}
}

extension NSScrollView {
	var contentOffset: CGPoint {
		contentView.bounds.origin
	}
	
	var contentInset: NSEdgeInsets {
		self.contentInsets
	}
}

#elseif canImport(UIKit)
import UIKit

typealias TableViewDiffableDataSource = UITableViewDiffableDataSource
public typealias ViewController = UIViewController
typealias TableView = UITableView
typealias ScrollView = UIScrollView
#endif

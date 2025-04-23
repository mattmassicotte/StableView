#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension ScrollView {
	var isBouncing: Bool {
		isBouncingTop || isBouncingBottom
	}
	
	var isBouncingTop: Bool {
		contentOffset.y < topInsetForBouncing - contentInset.top
	}
	
	var isBouncingBottom: Bool {
		let threshold: CGFloat
		
		if contentSize.height > frame.size.height {
			threshold = (contentSize.height - frame.size.height + contentInset.bottom + bottomInsetForBouncing)
		} else {
			threshold = topInsetForBouncing
		}
		
		return contentOffset.y > threshold
	}
	
	private var topInsetForBouncing: CGFloat {
		safeAreaInsets.top != 0.0 ? -safeAreaInsets.top : 0.0
	}
	
	private var bottomInsetForBouncing: CGFloat {
		safeAreaInsets.bottom
	}
}

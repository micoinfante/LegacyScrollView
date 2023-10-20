//
//  File.swift
//  
//
//  Created by Bruno Wide on 26/02/22.
//

import Foundation
import SwiftUI

public struct LegacyScrollViewProxy {

    internal var getScrollView: () -> UIScrollView
    internal var getRectOfContent: (_ id: Int) -> CGRect?
    internal var performScrollToPoint: (_ point: CGPoint, _ animated: Bool, _ duration: CGFloat, _ bounce: Bool) -> Void
    internal var performScrollToId: (_ id: Int, _ anchor: UnitPoint, _ animated: Bool, _ duration: CGFloat, _ bounce: Bool) -> Void
    internal var performScrollToIdIfNeeded: (_ id: Int, _ anchor: UnitPoint) -> Void

    /// Returns the UIScrollView
    public var scrollView: UIScrollView { getScrollView() }
    /// returns the content's CGRect
    public func rectOfContent<ID: Hashable>(id: ID) -> CGRect? { getRectOfContent(id.hashValue) }
    /// performs a scroll to a specific `CGPoint`
    public func scrollTo(point: UnitPoint, animated: Bool = true, duration: CGFloat = 0.5, bounce: Bool = false) { performScrollToPoint(CGPoint(x: point.x, y: point.y), animated, duration, bounce) }
    /// performs a scroll to an item with set `legacyID`
    public func scrollTo<ID: Hashable>(_ id: ID, anchor: UnitPoint = .top, animated: Bool = true, duration: CGFloat = 0.5, bounce: Bool = false) { performScrollToId(id.hashValue, anchor, animated, duration, bounce) }
    /// performs a scroll to an item with set `legacyID` if the item is out of the visible rect
    public func scrollToIdIfNeeded<ID: Hashable>(_ id: ID, anchor: UnitPoint = .top) { performScrollToIdIfNeeded(id.hashValue, anchor) }
}

extension LegacyScrollViewReader {
    func makeProxy(with view: LegacyUIScrollViewReader) -> LegacyScrollViewProxy {
        LegacyScrollViewProxy {
            view.scrollView!
        } getRectOfContent: { id in
            getRectOfContent(with: id, in: view)
        } performScrollToPoint: { point, animated, duration, bounce in
            performScrollTo(point: point, animated: animated, in: view, duration: duration, bounce: bounce)
        } performScrollToId: { id, anchor, animated, duration, bounce in
            performScrollTo(id, anchor: anchor, animated: animated, in: view, duration: duration, bounce: bounce)
        } performScrollToIdIfNeeded: { id, anchor in
            performScrollToIdIfNeeded(id, anchor: anchor, in: view)
        }
    }

    private func getRectOfContent(with id: Int, in view: LegacyUIScrollViewReader) -> CGRect? {
        guard
            let foundView = view.scrollView?.allSubviews.first(where: { $0.tag == id })?.superview
        else { return nil }

        return foundView.frame
    }

    private func performScrollTo(point: CGPoint, animated: Bool, in view: LegacyUIScrollViewReader, duration: CGFloat = 0.5, bounce: Bool = false) {
        if animated {
            if bounce {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [], animations: {
                    view.scrollView?.setContentOffset(point, animated: false)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: duration) {
                    view.scrollView?.setContentOffset(point, animated: false)
                }
            }
        } else {
            view.scrollView?.setContentOffset(point, animated: false)
        }
    }

    public func performScrollTo(_ id: Int, anchor: UnitPoint = .top, animated: Bool, in view: LegacyUIScrollViewReader, duration: CGFloat = 0.5, bounce: Bool = false) {
        guard let contentFrame = getRectOfContent(with: id, in: view) else { return }

        if animated {
            if bounce {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [], animations: {
                    view.scrollView?.setContentOffset(contentFrame.origin, animated: false)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: duration) {
                    view.scrollView?.setContentOffset(contentFrame.origin, animated: false)
                }
            }
        } else {
            view.scrollView?.setContentOffset(contentFrame.origin, animated: false)
        }
    }

    public func performScrollToIdIfNeeded(_ id: Int, anchor: UnitPoint = .top, in view: LegacyUIScrollViewReader) {
        guard
            let contentFrame = getRectOfContent(with: id, in: view),
            !(view.scrollView?.visibleRect ?? CGRect.null).contains(contentFrame)
        else { return }

        view.scrollView?.setContentOffset(contentFrame.origin, animated: true)
    }
}

extension UIView {
    var allSubviews: [UIView] {
        var ans: [UIView] = []

        for view in subviews {
            ans.append(view)
            ans += view.allSubviews
        }

        return ans
    }
}

public extension UIScrollView {
    var visibleRect: CGRect {
        CGRect(origin: contentOffset, size: visibleSize)
    }
}

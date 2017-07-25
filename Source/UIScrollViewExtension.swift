//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//

import Foundation
import UIKit

public extension UIScrollView {
    fileprivate func refreshViewWithTag(_ tag: Int) -> PullToRefreshView? {
        let pullToRefreshView = viewWithTag(tag)
        return pullToRefreshView as? PullToRefreshView
    }

    public func addPullToRefresh(options: PullToRefreshOption = PullToRefreshOption(), refreshCompletion: (() -> Void)?) {
        let refreshViewFrame = CGRect(x: 0, y: -PullToRefreshConst.height, width: self.frame.size.width, height: PullToRefreshConst.height)
        let refreshView = PullToRefreshView(options: options, frame: refreshViewFrame, refreshCompletion: refreshCompletion)
        refreshView.tag = PullToRefreshConst.pullTag
        addSubview(refreshView)
    }

    public func addPushToRefresh(options: PullToRefreshOption = PullToRefreshOption(), refreshCompletion: (() -> Void)?) {
        let refreshViewFrame = CGRect(x: 0, y: contentSize.height, width: self.frame.size.width, height: PullToRefreshConst.height)
        let refreshView = PullToRefreshView(options: options, frame: refreshViewFrame, refreshCompletion: refreshCompletion, down: false)
        refreshView.tag = PullToRefreshConst.pushTag
        addSubview(refreshView)
    }

    public func stopPullRefreshing(removeView: Bool = false) {
        let refreshView = refreshViewWithTag(PullToRefreshConst.pullTag)
        if removeView {
            refreshView?.state = .finish
        } else {
            refreshView?.state = .stop
        }
    }

    public func removePullToRefreshView() {
        let refreshView = refreshViewWithTag(PullToRefreshConst.pullTag)
        refreshView?.removeFromSuperview()
    }

    public func stopPushRefreshing(removeView: Bool = false) {
        let refreshView = refreshViewWithTag(PullToRefreshConst.pushTag)
        if removeView {
            refreshView?.state = .finish
        } else {
            refreshView?.state = .stop
        }
    }

    public func removePushToRefreshView() {
        let refreshView = refreshViewWithTag(PullToRefreshConst.pushTag)
        refreshView?.removeFromSuperview()
    }

    // If you want to PullToRefreshView fixed top potision, Please call this function in scrollViewDidScroll
    public func fixedPullToRefreshViewForDidScroll() {
        let pullToRefreshView = refreshViewWithTag(PullToRefreshConst.pullTag)
        if !PullToRefreshConst.fixedTop || pullToRefreshView == nil {
            return
        }
        var frame = pullToRefreshView!.frame
        if contentOffset.y < -PullToRefreshConst.height {
            frame.origin.y = contentOffset.y
            pullToRefreshView!.frame = frame
        } else {
            frame.origin.y = -PullToRefreshConst.height
            pullToRefreshView!.frame = frame
        }
    }
}

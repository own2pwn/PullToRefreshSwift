//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//

import UIKit

public struct PullToRefreshConst {
    static public var pullTag = 810
    static public var pushTag = 811
    static public var alpha = true
    static public var height: CGFloat = 80
    static public var imageName: String = "pulltorefresharrow.png"
    static public var animationDuration: Double = 0.5
    static public var fixedTop = true // PullToRefreshView fixed Top
}

public struct PullToRefreshOption {
    public var backgroundColor: UIColor
    public var indicatorColor: UIColor
    public var autoStopTime: Double // 0 is not auto stop
    public var fixedSectionHeader: Bool // Update the content inset for fixed section headers

    public init(backgroundColor: UIColor = .clear, indicatorColor: UIColor = .gray, autoStopTime: Double = 0, fixedSectionHeader: Bool = false) {
        self.backgroundColor = backgroundColor
        self.indicatorColor = indicatorColor
        self.autoStopTime = autoStopTime
        self.fixedSectionHeader = fixedSectionHeader
    }
}

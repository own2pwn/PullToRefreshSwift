//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//  Qiulang rewrites it to support pull down & push up
//

import UIKit

open class PullToRefreshView: UIView {

    enum PullToRefreshState {
        case pulling
        case triggered
        case refreshing
        case stop
        case finish
    }

    // MARK: Variables
    let contentOffsetKeyPath = "contentOffset"
    let contentSizeKeyPath = "contentSize"
    var kvoContext = "PullToRefreshKVOContext"

    fileprivate var options: PullToRefreshOption
    fileprivate var backgroundView: UIView
    fileprivate var arrow: UIImageView
    fileprivate var indicator: UIActivityIndicatorView
    fileprivate var scrollViewInsets: UIEdgeInsets = UIEdgeInsets.zero
    fileprivate var refreshCompletion: (() -> Void)?
    fileprivate var pull: Bool = true

    fileprivate var positionY: CGFloat = 0 {
        didSet {
            if self.positionY == oldValue {
                return
            }
            var frame = self.frame
            frame.origin.y = positionY
            self.frame = frame
        }
    }

    var state: PullToRefreshState = PullToRefreshState.pulling {
        didSet {
            if self.state == oldValue {
                return
            }
            switch self.state {
            case .stop:
                stopAnimating()
            case .finish:
                var duration = PullToRefreshConst.animationDuration
                var time = DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self.stopAnimating()
                }
                duration = duration * 2
                time = DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self.removeFromSuperview()
                }
            case .refreshing:
                startAnimating()
            case .pulling: // starting point
                arrowRotationBack()
            case .triggered:
                arrowRotation()
            }
        }
    }

    // MARK: UIView
    public convenience override init(frame: CGRect) {
        self.init(options: PullToRefreshOption(), frame: frame, refreshCompletion: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(options: PullToRefreshOption, frame: CGRect, refreshCompletion: (() -> Void)?, down: Bool = true) {
        self.options = options
        self.refreshCompletion = refreshCompletion

        backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        backgroundView.backgroundColor = self.options.backgroundColor
        backgroundView.autoresizingMask = UIViewAutoresizing.flexibleWidth

        arrow = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        arrow.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]

        arrow.image = UIImage(named: PullToRefreshConst.imageName, in: Bundle(for: type(of: self)), compatibleWith: nil)

        indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator.bounds = arrow.bounds
        indicator.autoresizingMask = arrow.autoresizingMask
        indicator.hidesWhenStopped = true
        indicator.color = options.indicatorColor
        pull = down

        super.init(frame: frame)
        addSubview(indicator)
        addSubview(backgroundView)
        addSubview(arrow)
        autoresizingMask = .flexibleWidth
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        arrow.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        arrow.frame = arrow.frame.offsetBy(dx: 0, dy: 0)
        indicator.center = arrow.center
    }

    open override func willMove(toSuperview superView: UIView!) {
        // superview NOT superView, DO NEED to call the following method
        // superview dealloc will call into this when my own dealloc run later!!
        removeRegister()
        guard let scrollView = superView as? UIScrollView else {
            return
        }
        scrollView.addObserver(self, forKeyPath: contentOffsetKeyPath, options: .initial, context: &kvoContext)
        if !pull {
            scrollView.addObserver(self, forKeyPath: contentSizeKeyPath, options: .initial, context: &kvoContext)
        }
    }

    fileprivate func removeRegister() {
        if let scrollView = superview as? UIScrollView {
            scrollView.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &kvoContext)
            if !pull {
                scrollView.removeObserver(self, forKeyPath: contentSizeKeyPath, context: &kvoContext)
            }
        }
    }

    deinit {
        self.removeRegister()
    }

    // MARK: KVO

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = object as? UIScrollView else {
            return
        }
        if keyPath == contentSizeKeyPath {
            positionY = scrollView.contentSize.height
            return
        }

        if !(context == &kvoContext && keyPath == contentOffsetKeyPath) {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        // Pulling State Check
        let offsetY = scrollView.contentOffset.y

        // Alpha set
        if PullToRefreshConst.alpha {
            var alpha = fabs(offsetY) / (frame.size.height + 40)
            if alpha > 0.8 {
                alpha = 0.8
            }
            arrow.alpha = alpha
        }

        if offsetY <= 0 {
            if !pull {
                return
            }

            if offsetY < -frame.size.height {
                // pulling or refreshing
                if scrollView.isDragging == false && state != .refreshing { // release the finger
                    state = .refreshing // startAnimating
                } else if state != .refreshing { // reach the threshold
                    state = .triggered
                }
            } else if state == .triggered {
                // starting point, start from pulling
                state = .pulling
            }
            return // return for pull down
        }

        // push up
        let upHeight = offsetY + scrollView.frame.size.height - scrollView.contentSize.height
        if upHeight > 0 {
            // pulling or refreshing
            if pull {
                return
            }
            if upHeight > frame.size.height {
                // pulling or refreshing
                if scrollView.isDragging == false && state != .refreshing { // release the finger
                    state = .refreshing // startAnimating
                } else if state != .refreshing { // reach the threshold
                    state = .triggered
                }
            } else if state == .triggered {
                // starting point, start from pulling
                state = .pulling
            }
        }
    }

    // MARK: private

    fileprivate func startAnimating() {
        indicator.startAnimating()
        arrow.isHidden = true
        guard let scrollView = superview as? UIScrollView else {
            return
        }
        scrollViewInsets = scrollView.contentInset

        var insets = scrollView.contentInset
        if pull {
            insets.top += frame.size.height
        } else {
            insets.bottom += frame.size.height
        }
        scrollView.bounces = false
        UIView.animate(withDuration: PullToRefreshConst.animationDuration,
                delay: 0,
                options: [],
                animations: {
                    scrollView.contentInset = insets
                },
                completion: { _ in
                    if self.options.autoStopTime != 0 {
                        let time = DispatchTime.now() + Double(Int64(self.options.autoStopTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: time) {
                            self.state = .stop
                        }
                    }
                    self.refreshCompletion?()
                })
    }

    fileprivate func stopAnimating() {
        indicator.stopAnimating()
        arrow.isHidden = false
        guard let scrollView = superview as? UIScrollView else {
            return
        }
        scrollView.bounces = true
        let duration = PullToRefreshConst.animationDuration
        UIView.animate(withDuration: duration,
                animations: {
                    scrollView.contentInset = self.scrollViewInsets
                    self.arrow.transform = CGAffineTransform.identity
                }, completion: { _ in
            self.state = .pulling
        })
    }

    fileprivate func arrowRotation() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            let rotationControl: CGFloat = -0.0000001
            let angle = CGFloat.pi - rotationControl
            self.arrow.transform = CGAffineTransform(rotationAngle: angle)
        }, completion: nil)
    }

    fileprivate func arrowRotationBack() {
        UIView.animate(withDuration: 0.2, animations: {
            self.arrow.transform = CGAffineTransform.identity
        })
    }
}

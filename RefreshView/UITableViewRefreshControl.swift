//
// Created by Tommy Sadiq Hinrichsen on 06/03/2017.
// Copyright (c) 2017 Eazy IT. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class UITableViewRefreshControl {

    fileprivate var headerView: RefreshView?
    var headerState: Variable<RefreshViewState>? {
        return headerView?.state
    }

    fileprivate var footerView: RefreshView?
    var footerState: Variable<RefreshViewState>? {
        return footerView?.state
    }

    fileprivate let tableView: UITableView

    fileprivate let disposeBag = DisposeBag()

    init(_ tableView: UITableView) {
        self.tableView = tableView
        assert(self.tableView.superview != nil, "table view must be added to superview before creating refresh controller")
        assert(self.tableView.delegate != nil, "table view must have delegate before create refresh controller")

        self.configureRx()
    }

    fileprivate func configureRx() {

        //Track refresh view states
        self.tableView.rx.contentOffset
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in

                    //Drag down animations
                    self?.shouldEnterWillRefreshTop()

                    //Pull up animation
                    self?.shouldEnterWillRefreshBottom()

                })
                .addDisposableTo(self.disposeBag)


        //Offset bottom refresh view when table view gets size
        self.tableView.rx.observeWeakly(CGSize.self, "contentSize")
                .distinctUntilChanged({ (size: CGSize?, other: CGSize?) -> Bool in
                    return size != nil && other != nil && size!.equalTo(other!)
                })
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in

                    self?.offsetFooterView()

                }).addDisposableTo(self.disposeBag)

        //Snap table view to position when user lets go so that header refresh view is aligned
//        self.tableView.rx.didEndDecelerating
//                .subscribeOn(MainScheduler.instance)
//                .subscribe(onNext: { [weak self] in
//
//                })
//                .addDisposableTo(self.disposeBag)

        //Check if user dragged beyond pull to refresh before letting go
        self.tableView.rx.willEndDragging
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in

                    guard let strongSelf: UITableViewRefreshControl = self else {
                        return
                    }

                    if let headerView: RefreshView = strongSelf.headerView {

                        if headerView.state.value == .willRefresh {
                            headerView.state.value = .refreshing
                            UIView.animate(withDuration: 0.25, animations: {
                                strongSelf.tableView.contentInset = UIEdgeInsetsMake(0, 0, strongSelf.tableView.contentInset.bottom, 0)
                            })
                        }
                    }

                    if let footerView: RefreshView = strongSelf.footerView {

                        if footerView.state.value == .willRefresh {
                            footerView.state.value = .refreshing
                            UIView.animate(withDuration: 0.25, animations: {
                                strongSelf.tableView.contentInset = UIEdgeInsetsMake(strongSelf.tableView.contentInset.top, 0, strongSelf.footerOffset, 0)
                            })
                        }
                    }

                }).addDisposableTo(self.disposeBag)

    }

    fileprivate func shouldEnterWillRefreshTop() {

        let currentScreenOffset = self.tableView.contentOffset.y + self.tableView.contentInset.top

        if currentScreenOffset > 0 {
            return
        }

        if let headerView: RefreshView = self.headerView {

            if headerView.state.value == .disabled || headerView.state.value == .refreshing || self.footerView?.state.value == .refreshing {
                return
            }

            if currentScreenOffset < -RefreshView.height {
                headerView.state.value = .willRefresh
            } else {
                headerView.state.value = .enabled
            }
        }
    }

    fileprivate func shouldEnterWillRefreshBottom() {

        if let footerView: RefreshView = self.footerView {

            if footerView.state.value == .disabled || footerView.state.value == .refreshing || self.headerView?.state.value == .refreshing {
                return
            }

            let hiddenViewPosition: CGRect = footerView.hiddenView.convert(footerView.hiddenView.bounds, to: nil)
            let tableViewPosition: CGRect = self.tableView.convert(self.tableView.bounds, to: nil)

            let currentScreenOffset = tableViewPosition.maxY - hiddenViewPosition.minY

            if currentScreenOffset < 0 {
                return
            }

            if currentScreenOffset > RefreshView.height {

                footerView.state.value = .willRefresh
            } else {
                footerView.state.value = .enabled
            }
        }
    }

    fileprivate var footerOffset: CGFloat {

        let contentHeight: CGFloat = self.tableView.contentSize.height + self.tableView.contentInset.top
        let tableViewHeight: CGFloat = self.tableView.bounds.size.height

        if contentHeight < tableViewHeight {

            let footerOffset = tableViewHeight - contentHeight + (RefreshView.height / 2)

            return footerOffset
        } else {
            return 0
        }
    }

    fileprivate func offsetFooterView() {

        if let footerView: RefreshView = self.footerView {
            footerView.offsetHiddenView(self.footerOffset)
        }
    }

    func finishRefreshing() {

        DispatchQueue.main.async {

            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.tableView.beginUpdates()
            self.tableView.endUpdates()

            var insets = UIEdgeInsetsMake(0, 0, 0, 0)

            if let headerView = self.headerView {
                switch headerView.state.value {
                case .disabled:
                    if self.tableView.contentOffset.y == 28.0 {
                        self.tableView.contentOffset = CGPoint.zero
                    }
                    break
                case .enabled, .willRefresh, .refreshing:
                    insets.top = -RefreshView.height / 2
                    headerView.state.value = .enabled
                }
            }

            if let footerView = self.footerView {
                switch footerView.state.value {
                case .disabled:
                    break
                case .enabled, .willRefresh, .refreshing:
                    insets.bottom = -RefreshView.height / 2
                    footerView.state.value = .enabled
                }
            }

            self.tableView.contentInset = insets

        }
    }

    func configureTopPullToRefresh(onBoardText: String, refreshText: String, releaseText: String, refreshingText: String) {

        self.headerView = RefreshView(position: .top, onBoardText: onBoardText, refreshText: refreshText, releaseText: releaseText, refreshingText: refreshingText)
        self.tableView.contentInset = UIEdgeInsetsMake(-RefreshView.height / 2, 0, self.tableView.contentInset.bottom, 0)
        self.tableView.tableHeaderView = self.headerView!

    }

    func configureBottomPullToRefresh(onBoardText: String, refreshText: String, releaseText: String, refreshingText: String) {

        self.footerView = RefreshView(position: .bottom, onBoardText: onBoardText, refreshText: refreshText, releaseText: releaseText, refreshingText: refreshingText)
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, -RefreshView.height / 2, 0)
        self.tableView.tableFooterView = self.footerView!

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

}

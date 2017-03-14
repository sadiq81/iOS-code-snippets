# Introduction
This is a top and bottom pull to refresh control for a tableview. 
It currently has dependencies to RxSwift and SnapKit, however these can written out

# Usage

## Initialization

```
let refreshControl = UITableViewRefreshControl(self.tableView)
refreshControl!.configureTopPullToRefresh(
        onBoardText: "PULLTOREFRESH_TOP_INFO".localized,
        refreshText: "PULLTOREFRESH_TOP_PULL".localized,
        releaseText: "PULLTOREFRESH_TOP_RELEASE".localized,
        refreshingText: "LOADING".localized)
refreshControl!.configureBottomPullToRefresh(
        onBoardText: "PULLTOREFRESH_BOTTOM_INFO".localized,
        refreshText: "PULLTOREFRESH_BOTTOM_PULL".localized,
        releaseText: "PULLTOREFRESH_BOTTOM_RELEASE".localized,
        refreshingText: "LOADING".localized)
```

## Listening to refresh

```
refreshControl!.headerState!.asObservable()
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (state) in
            if state == .refreshing {
                //Do something
            }
        })
        .addDisposableTo(self.disposeBag)

refreshControl!.footerState!.asObservable()
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (state) in
            if state == .refreshing {
                //Do something
            }
        })
        .addDisposableTo(self.disposeBag)
```

## End refreshing
      
```
refreshControl?.finishRefreshing()
```

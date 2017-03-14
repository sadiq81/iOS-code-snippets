//
// Created by Tommy Sadiq Hinrichsen on 06/03/2017.
// Copyright (c) 2017 Eazy IT. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift

class RefreshView: UIView {

    static let height: CGFloat = 56.0

    let position: RefreshViewPosition

    let onBoardText: String
    let refreshText: String
    let releaseText: String
    let refreshingText: String

    var state = Variable<RefreshViewState>(.disabled)
    let disposeBag = DisposeBag()

    let onBoardLabel = DSBLabel(size: 12, alignment: .center, type: .regular)

    let hiddenView = UIView(frame: CGRect.zero)
    let fetchImage = UIImageView(image: UIImage(named: ARROW_REFRESH)!)
    let stateLabel = DSBLabel(size: 12, alignment: .center, type: .bold)
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    init(position: RefreshViewPosition, onBoardText: String, refreshText: String, releaseText: String, refreshingText: String) {
        self.position = position
        self.onBoardText = onBoardText
        self.refreshText = refreshText
        self.releaseText = releaseText
        self.refreshingText = refreshingText

        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: RefreshView.height))

        self.configureView()
        self.configureRx()
        self.configureConstraints()
    }

    func configureView() {

        self.clipsToBounds = false

        self.onBoardLabel.text = self.onBoardText

        if self.position == .bottom {
            let upsideDownImage: UIImage = UIImage(cgImage: self.fetchImage.image!.cgImage!, scale: UIScreen.main.scale, orientation: .down)
            self.fetchImage.image = upsideDownImage
        }

        self.hiddenView.addSubviews(self.fetchImage, self.stateLabel, self.spinner)
        self.addSubviews(self.onBoardLabel, self.hiddenView)

    }

    func configureRx() {

        self.state.asObservable()
                .skip(1)
                .observeOn(MainScheduler.instance)
                .distinctUntilChanged()
                .subscribe(onNext: { [weak self] (state: RefreshViewState) in

                    guard let strongSelf = self else {
                        return
                    }

                    switch (state) {
                    case .disabled:
                        strongSelf.isHidden = true
                        strongSelf.frame = CGRect(
                                x: strongSelf.frame.origin.x,
                                y: strongSelf.frame.origin.y,
                                width: strongSelf.frame.size.width,
                                height: 0
                        )
                        strongSelf.spinner.stopAnimating()
                        break
                    case .enabled:
                        strongSelf.isHidden = false
                        strongSelf.frame = CGRect(
                                x: strongSelf.frame.origin.x,
                                y: strongSelf.frame.origin.y,
                                width: strongSelf.frame.size.width,
                                height: RefreshView.height
                        )
                        strongSelf.stateLabel.text = strongSelf.refreshText
                        strongSelf.fetchImage.isHidden = false
                        strongSelf.spinner.stopAnimating()

                        UIView.animate(withDuration: 0.3, animations: {
                            strongSelf.fetchImage.transform = CGAffineTransform(rotationAngle: 0)
                        })

                        break
                    case .willRefresh:
                        strongSelf.stateLabel.text = strongSelf.releaseText

                        UIView.animate(withDuration: 0.3, animations: {
                            strongSelf.fetchImage.transform = CGAffineTransform(rotationAngle: (180.0 * CGFloat(M_PI)) / 180.0)
                        })

                        break
                    case .refreshing:
                        strongSelf.stateLabel.text = strongSelf.refreshingText
                        strongSelf.fetchImage.isHidden = true
                        strongSelf.spinner.startAnimating()
                        break
                    }

                }).addDisposableTo(self.disposeBag)

    }

    func configureConstraints() {

        self.onBoardLabel.snp.makeConstraints { (make: ConstraintMaker) in
            make.height.equalTo(15)
            make.centerX.equalTo(self)
            switch self.position {
            case .top:
                make.bottom.equalTo(self).offset(-6.5)
            case .bottom:
                make.top.equalTo(self).offset(6.5)
            }
        }

        self.hiddenView.snp.makeConstraints { (make: ConstraintMaker) in
            make.left.right.equalTo(self)
            make.height.equalTo(RefreshView.height / 2)
            switch self.position {
            case .top:
                make.top.equalTo(self)
            case .bottom:
                make.bottom.equalTo(self)
            }
        }

        self.stateLabel.snp.makeConstraints { (make: ConstraintMaker) in
            make.centerY.equalTo(self.hiddenView)
            make.centerX.equalTo(self.hiddenView)
        }

        self.fetchImage.snp.makeConstraints { (make: ConstraintMaker) in
            make.centerY.equalTo(self.hiddenView)
            make.right.equalTo(self.stateLabel.snp.left).offset(-24)
        }

        self.spinner.snp.makeConstraints { (make: ConstraintMaker) in
            make.center.equalTo(self.fetchImage)
        }

    }

    func offsetHiddenView(_ offset: CGFloat) {

        self.hiddenView.snp.remakeConstraints { (make: ConstraintMaker) in
            make.left.right.equalTo(self)
            make.height.equalTo(RefreshView.height / 2)
            switch self.position {
            case .top:
                make.top.equalTo(self).offset(offset)
            case .bottom:
                make.bottom.equalTo(self).offset(offset)
            }
        }
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

}

enum RefreshViewPosition {
    case top
    case bottom
}

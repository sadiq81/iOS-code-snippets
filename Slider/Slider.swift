//
// Created by Tommy Sadiq Hinrichsen on 07/02/2017.
// Copyright (c) 2017 Eazy IT. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SnapKit

@objc
class Slider: UIView, UIGestureRecognizerDelegate {

    fileprivate let titleAlignment: TitleAlignment

    fileprivate let background = UIImageView(image: UIImage(named: SLIDER_GROOVE)!.stretchableImage(withLeftCapWidth: 13, topCapHeight: 0))
    fileprivate let knob = UIImageView(imageName: SLIDER_KNOB)
    fileprivate let titles: [String]
    fileprivate var intervals = [UIImageView]()
    fileprivate var labels = [UILabel]()

    fileprivate var panGesture: UIPanGestureRecognizer?
    fileprivate var tapGesture: UITapGestureRecognizer?

    let selectedValue = Variable<Int>(0)
    dynamic var selectedObjcValue: NSNumber = NSNumber(value: 0)

    fileprivate let disposeBag = DisposeBag()

    @objc
    init(titles: [String], titleAlignment: TitleAlignment = .top) {

        assert(titles.count >= 2 && !(titles.count > 2 && titleAlignment == .sides), "a minimum of 2 states, and only slider with 2 states can have labels on the sides")

        self.titles = titles
        self.titleAlignment = titleAlignment
        super.init(frame: CGRect.zero)

        self.configureView()
        self.configureKnob()
        self.configureLabels()
        self.configureIntervals()
        self.configureRx()
        self.configureConstraints()

        self.setIndex(0)

    }

    func setIndex(_ index: Int) {


        knob.snp.remakeConstraints { maker in

            if self.titleAlignment == .sides {
                let offsetDelta = self.knob.image!.size.width / 2.0
                let center: ConstraintItem = (index == 0 ? self.background.snp.left : self.background.snp.right)
                let offset = index == 0 ? offsetDelta : -offsetDelta
                maker.centerX.equalTo(center).offset(offset)
                maker.centerY.equalTo(self.background)

            } else {
                maker.centerX.equalTo(self.labels[index])/*.offset(newPosition)*/
                maker.centerY.equalTo(self.background)
            }
        }

        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, animations: self.setNeedsLayout)
        }

        self.selectedValue.value = Int(index)

    }

    fileprivate func configureView() {

        self.knob.isUserInteractionEnabled = true
        self.addSubviews(self.background, self.knob)

    }

    fileprivate func configureKnob() {

        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(DSBSlider.handleTap))
        self.addGestureRecognizer(tapGesture!)

        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(DSBSlider.handlePan))
        self.knob.addGestureRecognizer(panGesture!)

    }

    @objc
    private func handleTap(gestureRecognizer: UIGestureRecognizer) {

        if gestureRecognizer.state == UIGestureRecognizerState.ended {

            let touchLocation = gestureRecognizer.location(in: self.background)

            let percentage = touchLocation.x / self.background.frame.size.width
            var index = Int(round(percentage * CGFloat(self.titles.count - 1)))

            if index < 0 {
                index = 0
            } else if index > (self.titles.count - 1) {
                index = self.titles.count - 1
            }

            self.setIndex(index)

        }
    }

    @objc
    private func handlePan(gestureRecognizer: UIGestureRecognizer) {

        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return
        }

        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {

            let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
            let newCenter = CGPoint(x: gestureRecognizer.view!.center.x + translation.x, y: gestureRecognizer.view!.center.y)

            let minX = self.titleAlignment == .sides ? self.background.frame.origin.x : self.labels.first!.center.x
            let maxX = self.titleAlignment == .sides ? (self.background.frame.origin.x + self.background.frame.size.width) : self.labels.last!.center.x

            if newCenter.x < minX || newCenter.x > maxX {
                return
            }

            gestureRecognizer.view!.center = newCenter
            gestureRecognizer.setTranslation(CGPoint.zero, in: self)
        } else if gestureRecognizer.state == UIGestureRecognizerState.ended {
            self.handleTap(gestureRecognizer: gestureRecognizer)
        }
    }

    fileprivate func configureLabels() {

        let first = Label(size: 14, alignment: self.titleAlignment == .top ? .center : .right, type: .regular, color: UIColor.dsbTxtGray())
        first.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        first.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        first.text = self.titles.first!
        self.addSubview(first)
        self.labels.append(first)

        let last = Label(size: 14, alignment: (self.titleAlignment == .top ? .center : .left), type: .regular, color: UIColor.dsbTxtGray())
        last.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        last.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        last.text = self.titles.last!
        self.addSubview(last)
        self.labels.append(last)

    }

    fileprivate func configureIntervals() {

        let stackView = UIStackView(frame: CGRect.zero)
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.axis = .vertical
        self.insertSubview(stackView, belowSubview: self.knob)
        stackView.snp.makeConstraints { make in
            make.left.centerY.right.equalTo(self.background)
        }

        for index in 1 ..< (titles.count - 1) {

            let interval = UIImageView(image: UIImage(named: SLIDER_GROOVE_KNOB))
            interval.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(interval)

            let label = Label(size: 14, alignment: .center, type: .regular, color: UIColor.txtGray())
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = self.titles[index]
            self.addSubview(label)
            self.labels.insert(label, at: index)

            label.snp.makeConstraints { make in
                make.centerX.equalTo(interval)
                make.bottom.equalTo(self.background.snp.top).offset(-kEdgeSpacing)
            }
        }
    }

    fileprivate func configureRx() {

        self.selectedValue
                .asObservable()
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [unowned self](value) in

                    self.selectedObjcValue = NSNumber(value: value)

                    UIView.animate(withDuration: 0.2) {

                        self.labels.forEach { label in
                            label.textColor = UIColor.dsbTxtGray()
                        }

                        self.labels[value].textColor = UIColor.dsbDarkRed()
                        self.layoutIfNeeded()
                    }


                })
                .addDisposableTo(self.disposeBag)
    }

    fileprivate func configureConstraints() {

        self.translatesAutoresizingMaskIntoConstraints = false

        self.labels.first!.snp.makeConstraints { make in
            if self.titleAlignment == .sides {
                make.left.equalTo(self).offset(9)
                make.centerY.equalTo(self.background)
            } else {
                make.top.equalTo(self)
                make.centerX.equalTo(self.background.snp.left).offset((self.knob.image!.size.width / 2.0))
                make.bottom.equalTo(self.background.snp.top).offset(-kEdgeSpacing)
            }
        }

        self.labels.last!.snp.makeConstraints { make in
            if self.titleAlignment == .sides {
                make.right.equalTo(self).offset(-9)
                make.centerY.equalTo(self.background)
//                make.width.equalTo(self.labels.first!)
            } else {
                make.top.equalTo(self)
                make.centerX.equalTo(self.background.snp.right).offset(-(self.knob.image!.size.width / 2.0))
                make.bottom.equalTo(self.background.snp.top).offset(-kEdgeSpacing)
            }
        }

        self.background.translatesAutoresizingMaskIntoConstraints = false

        self.background.snp.makeConstraints { make in
            if self.titleAlignment == .sides {
                make.centerY.equalTo(self)
                make.left.equalTo(self.labels.first!.snp.right).offset(kEdgeSpacing)
                make.right.equalTo(self.labels.last!.snp.left).offset(-kEdgeSpacing)
            } else {
                make.left.right.equalTo(self)
                make.height.equalTo(self.background.image!.size.height)
                make.bottom.equalTo(self)
            }
        }

        self.knob.translatesAutoresizingMaskIntoConstraints = false
//
//        self.knob.snp.makeConstraints { make in
//            make.left.equalTo(self.background)
//            make.centerY.equalTo(self.background)
//        }

        self.snp.makeConstraints { make in
            if self.titleAlignment == .sides {
                make.height.greaterThanOrEqualTo(22)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    func alignCenter(sliderWidth: Int = 80) {
        if self.titleAlignment == .sides {
            self.background.snp.remakeConstraints { make in
                make.center.equalTo(self)
                make.width.equalTo(sliderWidth)
            }
            self.labels.first!.snp.remakeConstraints { make in
                make.right.equalTo(self.background.snp.left).offset(-kEdgeSpacing)
                make.centerY.equalTo(self.background)
            }
            self.labels.last!.snp.remakeConstraints { make in
                make.left.equalTo(self.background.snp.right).offset(kEdgeSpacing)
                make.centerY.equalTo(self.background)
            }
        }
    }

}

@objc
enum TitleAlignment: Int {
    case sides
    case top
}

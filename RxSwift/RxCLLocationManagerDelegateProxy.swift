//
//  RxCLLocationManagerDelegateProxy.swift
//  RxCocoa
//
//  Created by Carlos GarcÃ­a on 8/7/15.
//  Copyright Â© 2015 Krunoslav Zaher. All rights reserved.
//

import CoreLocation

#if !RX_NO_MODULE

import RxSwift
import RxCocoa

#endif

class RxCLLocationManagerDelegateProxy: DelegateProxy, CLLocationManagerDelegate, DelegateProxyType {

    class func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        guard let locationManager = object as? CLLocationManager else {
            fatalError("delegate does not match")
        }
        return locationManager.delegate
    }

    class func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        guard let locationManager = object as? CLLocationManager else {
            fatalError("delegate does not match")
        }
        locationManager.delegate = delegate as? CLLocationManagerDelegate
    }
}

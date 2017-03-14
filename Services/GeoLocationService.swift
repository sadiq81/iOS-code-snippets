//
// Created by Tommy Sadiq Hinrichsen on 04/10/2016.
// Copyright (c) 2016 Eazy IT. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import RxSwift
import RxCocoa

class GeoLocationService {

    static let sharedInstance = GeoLocationService()

    fileprivate (set) var authorized: Observable<Bool>
    fileprivate (set) var location: Observable<CLLocation>

    fileprivate let locationManager = CLLocationManager()
    fileprivate let disposeBag = DisposeBag()

    fileprivate var subscribersCount = 0

    fileprivate init() {

        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation

        authorized = locationManager.rx.didChangeAuthorizationStatus.map({ (status: CLAuthorizationStatus) -> Bool in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                return true
            default:
                return false
            }
        }).catchError({ (error: Error) -> Observable<Bool> in
            return Observable<Bool>.just(false)
        })

        self.location = locationManager.rx.didUpdateLocations
                .filter({ (locations: [CLLocation]) -> Bool in
                    return locations.count > 0 && locations[0].isNew()
                })
                .map({ (locations: [CLLocation]) -> CLLocation in
                    return locations[0]
                })
                .catchError({ (error: Error) -> Observable<CLLocation> in
                    return Observable<CLLocation>.just(CLLocation(latitude: 0.0, longitude: 0.0))
                })

        self.location = self.location.do(onSubscribe: { [unowned self] in
            self.subscribersCount = self.subscribersCount + 1
            if (self.subscribersCount >= 1) {
                self.locationManager.startUpdatingLocation()
            }

        }, onDispose: { [unowned self] in
            self.subscribersCount = self.subscribersCount - 1
            if (self.subscribersCount <= 1) {
                self.locationManager.stopUpdatingLocation()
            }
        })

        self.locationManager.requestWhenInUseAuthorization()

    }
}

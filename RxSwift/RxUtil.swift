//
//  RxUtil.swift
//
//  Created by Tommy Sadiq Hinrichsen on 03/01/2017.
//  Copyright © 2017 Eazy IT. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object as AnyObject, targetType: resultType)
    }

    return returnValue
}

func castOptionalOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T? {
    if NSNull().isEqual(object) {
        return nil
    }

    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object as AnyObject, targetType: resultType)
    }

    return returnValue
}

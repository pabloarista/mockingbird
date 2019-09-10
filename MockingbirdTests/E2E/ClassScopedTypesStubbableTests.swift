//
//  ClassScopedTypesStubbableTests.swift
//  MockingbirdTests
//
//  Created by Andrew Chang on 8/27/19.
//

import Foundation
import Mockingbird
@testable import MockingbirdTestsHost

// MARK: - Stubbable declarations

private protocol StubbableTopLevelType {
  func topLevelMethod(param1: @escaping @autoclosure () -> TopLevelType.SecondLevelType,
                      param2: @escaping @autoclosure () -> TopLevelType.SecondLevelType.ThirdLevelType)
    -> Mockable<MethodDeclaration, (TopLevelType.SecondLevelType, TopLevelType.SecondLevelType.ThirdLevelType) -> Bool, Bool>
}
extension TopLevelTypeMock: StubbableTopLevelType {}

private protocol StubbableSecondLevelType {
  func secondLevelMethod(param1: @escaping @autoclosure () -> TopLevelType,
                         param2: @escaping @autoclosure () -> TopLevelType.SecondLevelType.ThirdLevelType)
    -> Mockable<MethodDeclaration, (TopLevelType, TopLevelType.SecondLevelType.ThirdLevelType) -> Bool, Bool>
}
extension TopLevelTypeMock.SecondLevelTypeMock: StubbableSecondLevelType {}

private protocol StubbableThirdLevelType {
  func thirdLevelMethod(param1: @escaping @autoclosure () -> TopLevelType,
                        param2: @escaping @autoclosure () -> TopLevelType.SecondLevelType)
    -> Mockable<MethodDeclaration, (TopLevelType, TopLevelType.SecondLevelType) -> Bool, Bool>
}
extension TopLevelTypeMock.SecondLevelTypeMock.ThirdLevelTypeMock: StubbableThirdLevelType {}

private protocol StubbableThirdLevelInheritingTopLevelType: StubbableTopLevelType {
  func thirdLevelInheritingMethod()
    -> Mockable<MethodDeclaration, () -> TopLevelType, TopLevelType>
}
extension TopLevelTypeMock.SecondLevelTypeMock.ThirdLevelInheritingTopLevelTypeMock:
StubbableThirdLevelInheritingTopLevelType {}

private protocol StubbableThirdLevelInheritingThirdLevelType: StubbableThirdLevelType {
  func thirdLevelInheritingMethod()
    -> Mockable<MethodDeclaration, () -> TopLevelType.SecondLevelType.ThirdLevelType, TopLevelType.SecondLevelType.ThirdLevelType>
}
extension TopLevelTypeMock.SecondLevelTypeMock.ThirdLevelInheritingThirdLevelTypeMock:
StubbableThirdLevelInheritingThirdLevelType {}

private protocol StubbableThirdLevelInheritingPartiallyQualifiedThirdLevelType: StubbableThirdLevelType {
  func thirdLevelInheritingMethod()
    -> Mockable<MethodDeclaration, () -> TopLevelType.SecondLevelType.ThirdLevelType, TopLevelType.SecondLevelType.ThirdLevelType>
}
extension TopLevelTypeMock.SecondLevelTypeMock.ThirdLevelInheritingPartiallyQualifiedThirdLevelTypeMock:
StubbableThirdLevelInheritingPartiallyQualifiedThirdLevelType {}

private protocol StubbableThirdLevelInheritingFullyQualifiedThirdLevelType: StubbableThirdLevelType {
  func thirdLevelInheritingMethod()
    -> Mockable<MethodDeclaration, () -> TopLevelType.SecondLevelType.ThirdLevelType, TopLevelType.SecondLevelType.ThirdLevelType>
}
extension TopLevelTypeMock.SecondLevelTypeMock.ThirdLevelInheritingFullyQualifiedThirdLevelTypeMock:
StubbableThirdLevelInheritingFullyQualifiedThirdLevelType {}
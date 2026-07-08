import Foundation

protocol ThrowingProtocol {
  func throwingMethod() throws
  func throwingMethod() throws -> Bool
  func throwingMethod(block: () throws -> Bool) throws
}

protocol RethrowingProtocol {
  func rethrowingMethod(block: () throws -> Bool) rethrows
  func rethrowingMethod(block: () throws -> Bool) rethrows -> Bool
}

#if swift(>=6.0)
enum TypedThrowingError: Error {
  case failure
}

protocol TypedThrowingProtocol {
  func typedThrowingMethod() throws(TypedThrowingError) -> Bool
  func typedThrowingMethod(block: () throws(TypedThrowingError) -> Bool) throws(TypedThrowingError)
}
#endif

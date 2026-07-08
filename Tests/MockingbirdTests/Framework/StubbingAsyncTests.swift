import Foundation
import Mockingbird
@testable import MockingbirdTestsHost
import XCTest

#if swift(>=5.5.2)
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension XCTest {
  func XCTAssertThrowsAsyncError<T: Sendable>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "XCTAssertThrowsAsyncError failed: did not throw an error",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
  ) async {
    do {
      _ = try await expression()
      XCTFail(message(), file: file, line: line)
    } catch {
      errorHandler(error)
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class StubbingAsyncTests: BaseTestCase {
  
  struct FakeError: Error {}
  
  var asyncProtocol: AsyncProtocolMock!
  var asyncProtocolInstance: AsyncProtocol { asyncProtocol }
  
  override func setUp() {
    asyncProtocol = mock(AsyncProtocol.self)
  }
  
  func testStubAsyncMethodVoid() async {
    given(await asyncProtocol.asyncMethodVoid()).willReturn()
    await asyncProtocolInstance.asyncMethodVoid()
    verify(await asyncProtocol.asyncMethodVoid()).wasCalled()
  }
  
  func testStubAsyncMethod_returnsValue() async {
    given(await asyncProtocol.asyncMethod()) ~> true
    
    let result: Bool = await asyncProtocolInstance.asyncMethod()

    XCTAssertEqual(result, true)
    verify(await asyncProtocol.asyncMethod()).wasCalled()
  }
  
  func testStubAsyncMethodWithParameter_returnsValue() async {
    given(await asyncProtocol.asyncMethod(parameter: any())) ~> 2
    
    let result: Int = await asyncProtocolInstance.asyncMethod(parameter: "parameter")

    XCTAssertEqual(result, 2)
    verify(await asyncProtocol.asyncMethod(parameter: "parameter")).wasCalled()
  }
  
  func testStubAsyncThrowingMethod_returnsValue() async throws {
    given(await asyncProtocol.asyncThrowingMethod()) ~> 1
    
    let result: Int = try await asyncProtocolInstance.asyncThrowingMethod()

    XCTAssertEqual(result, 1)
    verify(await asyncProtocol.asyncThrowingMethod()).wasCalled()
  }
  
  func testStubAsyncThrowingMethod_throwsError() async throws {
    given(await asyncProtocol.asyncThrowingMethod()) ~> { () throws -> Int in throw FakeError() }
    await XCTAssertThrowsAsyncError(try await asyncProtocolInstance.asyncThrowingMethod())
    verify(await asyncProtocol.asyncThrowingMethod()).wasCalled()
  }
  
  func testStubAsyncVariable_returnsValue() async {
    given(await asyncProtocol.getAsyncVariable()) ~> true
    
    let result: Bool = await asyncProtocolInstance.asyncVariable
    
    XCTAssertTrue(result)
    verify(await asyncProtocol.getAsyncVariable()).wasCalled()
  }
  
  func testStubThrowingVariable_returnsValue() throws {
    given(asyncProtocol.getThrowingVariable()) ~> true
    
    let result: Bool = try asyncProtocolInstance.throwingVariable
    
    XCTAssertTrue(result)
    verify(asyncProtocol.getThrowingVariable()).wasCalled()
  }
  
  func testStubAsyncThrowingVariable_returnsValue() async throws {
    given(await asyncProtocol.getAsyncThrowingVariable()) ~> 1
    
    let result: Int = try await asyncProtocolInstance.asyncThrowingVariable
    
    XCTAssertEqual(result, 1)
    verify(await asyncProtocol.getAsyncThrowingVariable()).wasCalled()
  }
  
  func testStubAsyncThrowingVariable_throwsError() async throws {
    given(await asyncProtocol.getAsyncThrowingVariable()) ~> { () throws -> Int in throw FakeError() }
    await XCTAssertThrowsAsyncError(try await asyncProtocolInstance.asyncThrowingVariable)
    verify(await asyncProtocol.getAsyncThrowingVariable()).wasCalled()
  }
  
  func testStubAsyncClosureMethod() async throws {
    given(await asyncProtocol.asyncClosureMethod(block: any())).willReturn()
    await asyncProtocolInstance.asyncClosureMethod(block: { true })
    verify(await asyncProtocol.asyncClosureMethod(block: any())).wasCalled()
  }
  
  func testStubAsyncClosureThrowingMethod_returnsValue() async throws {
    given(await asyncProtocol.asyncClosureThrowingMethod(block: any())) ~> true
    
    let result: Bool = try await asyncProtocolInstance.asyncClosureThrowingMethod(block: { false })

    XCTAssertTrue(result)
    verify(await asyncProtocol.asyncClosureThrowingMethod(block: any())).wasCalled()
  }
  
  func testStubAsyncClosureThrowingMethod_throwsError() async throws {
    given(await asyncProtocol.asyncClosureThrowingMethod(block: any())) ~> { _ in throw FakeError() }
    await XCTAssertThrowsAsyncError(try await asyncProtocolInstance.asyncClosureThrowingMethod(block: { true }))
    verify(await asyncProtocol.asyncClosureThrowingMethod(block: any())).wasCalled()
  }
  
  func testStubAsyncClosureThrowingMethod_returnsValueFromBlock() async throws {
    given(await asyncProtocol.asyncClosureThrowingMethod(block: any())) ~> { try await $0() }
    
    let result: Bool = try await asyncProtocolInstance.asyncClosureThrowingMethod(block: { true })

    XCTAssertTrue(result)
    verify(await asyncProtocol.asyncClosureThrowingMethod(block: any())).wasCalled()
  }
  
  func testStubAsyncClosureThrowingMethod_throwsErrorFromBlock() async throws {
    given(await asyncProtocol.asyncClosureThrowingMethod(block: any())) ~> { try await $0() }
    await XCTAssertThrowsAsyncError(try await asyncProtocolInstance.asyncClosureThrowingMethod(block: { throw FakeError() }))
    verify(await asyncProtocol.asyncClosureThrowingMethod(block: any())).wasCalled()
  }
  
}
#endif

import XCTest
import Driver
@testable import Compiler

final class NameBindingTests: XCTestCase {

  func testBuiltinAliases() throws {
    let source: SourceFile = """
    type A = Any
    type B = Unit
    type C = Nothing
    """
    try withTestCase(source, NameBindingTests.action)
  }

  func testNameBinding() throws {
    try withTestCases(in: "TestCases/NameBinding", NameBindingTests.action)
  }

  private static func action(source: SourceFile, driver: inout Driver) throws -> [Diag] {
    let moduleName = source.url.deletingPathExtension().lastPathComponent
    let moduleDecl = try driver.parse(moduleName: moduleName, sources: [source])

    var walker = Walker(
      binder: NameBinder(modules: driver.compiler.modules, stdlib: driver.compiler.stdlib))
    walker.walk(decl: moduleDecl)
    return walker.binder.diags
  }

}

fileprivate struct Walker: NodeWalker {

  typealias Result = Bool

  var parent: Node?

  var innermostSpace: DeclSpace?

  var binder: NameBinder

  mutating func willVisit(_ sign: Sign) -> (shouldWalk: Bool, nodeBefore: Sign) {
    if let name = sign as? NameSign {
      _ = binder.resolve(name, unqualifiedFrom: innermostSpace!)
      return (shouldWalk: false, nodeBefore: name)
    } else {
      return (shouldWalk: true, nodeBefore: sign)
    }
  }

}

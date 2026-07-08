import Foundation
import SourceKittenFramework

typealias StructureDictionary = [String: SourceKitRepresentable]

extension SwiftDeclarationKind {
  init?(from dictionary: StructureDictionary) {
    guard let rawKind = dictionary[SwiftDocKey.kind.rawValue] as? String else { return nil }
    self.init(rawValue: rawKind)
  }
  
  var isMockable: Bool {
    switch self {
    case .class, .protocol: return true
    default: return false
    }
  }
  
  var isParsable: Bool {
    switch self {
    case .class, .protocol, .struct, .enum, .extension, .typealias: return true
    default: return false
    }
  }
  
  var isMethod: Bool {
    switch self {
    case .functionMethodInstance,
         .functionMethodStatic,
         .functionMethodClass,
         .functionSubscript: return true
    default: return false
    }
  }
  
  var isVariable: Bool {
    switch self {
    case .varInstance, .varStatic, .varClass: return true
    default: return false
    }
  }
  
  var typeScope: TypeScope {
    switch self {
    case .functionMethodClass, .varClass: return .class
    case .functionMethodStatic, .varStatic: return .static
    default: return .instance
    }
  }
}

enum TypeScope: String, Comparable {
  case `instance` = "instance"
  case `static` = "static"
  case `class` = "class"
  
  func isMockable(in kind: SwiftDeclarationKind) -> Bool {
    switch self {
    case .instance, .class: return true
    case .static: return kind == .protocol
    }
  }
  
  var isStatic: Bool {
    switch self {
    case .class, .static: return true
    case .instance: return false
    }
  }
  
  static func < (lhs: TypeScope, rhs: TypeScope) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}

struct Attributes: OptionSet, Hashable {
  private(set) var rawValue: Int
  private(set) var declarations = [String]()
  init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  // MARK: SourceKit-provided attributes
  static let available = Attributes(rawValue: 1 << 0)
  static let final = Attributes(rawValue: 1 << 1)
  static let required = Attributes(rawValue: 1 << 2)
  static let weak = Attributes(rawValue: 1 << 3)
  static let `rethrows` = Attributes(rawValue: 1 << 4)
  static let convenience = Attributes(rawValue: 1 << 5)
  static let override = Attributes(rawValue: 1 << 6)
  static let objcName = Attributes(rawValue: 1 << 7)
  static let `optional` = Attributes(rawValue: 1 << 8)
  
  // MARK: Inferred attributes
  static let constant = Attributes(rawValue: 1 << 9)
  static let readonly = Attributes(rawValue: 1 << 10)
  static let async = Attributes(rawValue: 1 << 11)
  static let `throws` = Attributes(rawValue: 1 << 12)
  static let `inout` = Attributes(rawValue: 1 << 13)
  static let variadic = Attributes(rawValue: 1 << 14)
  static let failable = Attributes(rawValue: 1 << 15)
  static let unwrappedFailable = Attributes(rawValue: 1 << 16)
  static let closure = Attributes(rawValue: 1 << 17)
  static let escaping = Attributes(rawValue: 1 << 18)
  static let autoclosure = Attributes(rawValue: 1 << 19)
    
  static let sendable = Attributes(rawValue: 1 << 20)
  static let conventionBlock = Attributes(rawValue: 1 << 21)
  static let custom = Attributes(rawValue: 1 << 22)
  
  // MARK: Custom attributes
  static let implicit = Attributes(rawValue: 1 << 20)
  
  static let attributesKey = "key.attributes"
  static let attributeKey = "key.attribute"
}

extension Attributes {
  init?(from kind: SwiftDeclarationAttributeKind) {
    switch kind {
    case .available: self = .available
    case .final: self = .final
    case .required: self = .required
    case .weak: self = .weak
    case .rethrows: self = .rethrows
    case .convenience: self = .convenience
    case .override: self = .override
    case .objcName: self = .objcName
    case .`optional`: self = .`optional`
    case ._custom: self = .custom
    default: return nil
    }
  }
  
  /// It's necessary to abuse named attributes, e.g. `@objc(anything)` as custom attributes on older
  /// Swift versions results in an error rather than returning `source.decl.attribute._custom`.
  enum CustomAttributeDeclaration: String {
    /// The method is defined by a protocol and can be synthesized by the Swift compiler. For
    /// initializers like in `Decodable`, subclasses that define any designated initializers must
    /// now override the synthesized required initializer.
    case implicit = "@objc(mkb_implicit)"
  }
  
  init?(from declaration: CustomAttributeDeclaration) {
    switch declaration {
    case .implicit: self = .implicit
    }
  }
  
  mutating func insert(_ declaration: String) {
    declarations.append(declaration)
  }
  
  // DRAGON: Using the built-in `insert` method overwrites other members in the `OptionSet`.
  mutating func insert(_ newMember: Attributes) {
    rawValue |= newMember.rawValue
  }
  
  init(from dictionary: StructureDictionary, source: Data? = nil) {
    var attributes = Attributes()
    guard let rawAttributes = dictionary[Attributes.attributesKey] as? [StructureDictionary] else {
      self = attributes
      return
    }
    for rawAttributeDictionary in rawAttributes {
      guard let rawAttribute = rawAttributeDictionary[Attributes.attributeKey] as? String,
        let attributeKind = SwiftDeclarationAttributeKind(rawValue: rawAttribute),
        let attribute = Attributes(from: attributeKind) else { continue }
      if attribute == .custom {
        guard let source = source,
          let declaration = SourceSubstring.key.extract(from: rawAttributeDictionary,
                                                        contents: source),
          declaration.isGlobalActorAttributeDeclaration else { continue }
        attributes.insert(declaration)
        attributes.insert(attribute)
        continue
      }
      if attribute.shouldExtractDeclaration, let source = source,
        let declaration = SourceSubstring.key.extract(from: rawAttributeDictionary,
                                                      contents: source) {
        if let customAttributeDeclaration = CustomAttributeDeclaration(rawValue: declaration),
          let customAttribute = Attributes(from: customAttributeDeclaration) {
          attributes.insert(customAttribute)
        } else { // Don't include raw custom attribute declarations, because it won't compile.
          attributes.insert(declaration)
        }
      }
      attributes.insert(attribute)
    }
    self = attributes
  }
  
  var shouldExtractDeclaration: Bool {
    switch self {
    case .available, .objcName: return true
    default: return false
    }
  }
}

private extension String {
  var isGlobalActorAttributeDeclaration: Bool {
    let declaration = trimmingCharacters(in: .whitespacesAndNewlines)
    guard declaration.hasPrefix("@") else { return false }
    
    guard let name = declaration
      .dropFirst()
      .prefix(while: { !$0.isWhitespace && $0 != "(" })
      .split(separator: ".")
      .last
      .map(String.init) else { return false }
    return name == "MainActor" || name.hasSuffix("Actor")
  }
}

enum AccessLevel: String, CustomStringConvertible {
  case `open` = "source.lang.swift.accessibility.open"
  case `public` = "source.lang.swift.accessibility.public"
  case `internal` = "source.lang.swift.accessibility.internal"
  case `fileprivate` = "source.lang.swift.accessibility.fileprivate"
  case `private` = "source.lang.swift.accessibility.private"
  
  static let accessLevelKey = "key.accessibility"
  static let setterAccessLevelKey = "key.setter_accessibility"
  
  var description: String {
    switch self {
    case .open: return "open"
    case .public: return "public"
    case .internal: return "internal"
    case .fileprivate: return "fileprivate"
    case .private: return "private"
    }
  }
  
  // In Swift 5.2, SourceKit no longer always returns an explicit access level for all structures.
  static let defaultLevel = AccessLevel.internal
  
  init?(from dictionary: StructureDictionary) {
    guard let rawAccessLevel = dictionary[AccessLevel.accessLevelKey] as? String else { return nil }
    self.init(rawValue: rawAccessLevel)
  }
  
  init?(setter dictionary: StructureDictionary) {
    guard let rawAccessLevel = dictionary[AccessLevel.setterAccessLevelKey] as? String
      else { return nil }
    self.init(rawValue: rawAccessLevel)
  }
  
  var isMockable: Bool { // For types or member declarations.
    return self != .fileprivate && self != .private
  }
  
  func isMockableType(withinSameModule: Bool) -> Bool {
    switch self {
    case .open: return true
    case .public: return true // Could inherit members from externally defined types.
    case .internal: return withinSameModule
    case .fileprivate, .private: return false
    }
  }
  
  func isMockableMember(in context: SwiftDeclarationKind, withinSameModule: Bool) -> Bool {
    switch self {
    case .open: return true
    case .public: return context == .protocol || withinSameModule
    case .internal: return withinSameModule
    case .fileprivate, .private: return false
    }
  }
  
  func isInheritableType(withinSameModule: Bool) -> Bool {
    switch self {
    case .open: return true
    case .public: return withinSameModule
    case .internal: return withinSameModule
    case .fileprivate, .private: return false
    }
  }
}

struct EffectSpecifiers {
  enum Throwing {
    case none
    case throwing(typeName: String?)
    case rethrowing
  }
  
  static let none = EffectSpecifiers()
  
  let isAsync: Bool
  let throwing: Throwing
  
  init(isAsync: Bool = false, throwing: Throwing = .none) {
    self.isAsync = isAsync
    self.throwing = throwing
  }
  
  init(from declaration: Substring) {
    let attributes = declaration.trimmingCharacters(in: .whitespacesAndNewlines)[...]
    self.init(
      isAsync: attributes.range(of: #"\basync\b"#, options: .regularExpression) != nil,
      throwing: EffectSpecifiers.parseThrowingEffect(from: attributes)
    )
  }
  
  var isThrowing: Bool {
    switch throwing {
    case .none: return false
    case .throwing, .rethrowing: return true
    }
  }
  
  var isRethrowing: Bool {
    switch throwing {
    case .rethrowing: return true
    case .none, .throwing: return false
    }
  }
  
  var throwingTypeName: String? {
    switch throwing {
    case .throwing(let typeName): return typeName
    case .none, .rethrowing: return nil
    }
  }
  
  var hasSelfConstraint: Bool {
    return throwingTypeName?.contains(SerializationRequest.Constants.selfTokenIndicator) == true
  }
  
  func declaration(allowRethrows: Bool = true) -> String {
    var attributes = isAsync ? " async" : ""
    switch throwing {
    case .none:
      break
    case .throwing(let typeName):
      attributes += typeName.map({ " throws(\($0))" }) ?? " throws"
    case .rethrowing:
      attributes += allowRethrows ? " rethrows" : " throws"
    }
    return attributes
  }
  
  func serialized(with request: SerializationRequest) -> EffectSpecifiers {
    guard let throwingTypeName = throwingTypeName else { return self }
    let serializedTypeName = DeclaredType(from: throwingTypeName).serialize(with: request)
    return EffectSpecifiers(isAsync: isAsync, throwing: .throwing(typeName: serializedTypeName))
  }
  
  private static func parseThrowingEffect(from attributes: Substring) -> Throwing {
    guard attributes.range(of: #"\brethrows\b"#, options: .regularExpression) == nil else {
      return .rethrowing
    }
    guard let throwsRange = attributes.range(of: #"\bthrows\b"#, options: .regularExpression) else {
      return .none
    }
    let suffix = attributes[throwsRange.upperBound...]
      .trimmingCharacters(in: .whitespacesAndNewlines)[...]
    guard suffix.first == "(" else { return .throwing(typeName: nil) }
    
    let typeStartIndex = suffix.index(after: suffix.startIndex)
    guard let typeEndIndex = suffix[typeStartIndex...].firstIndex(of: ")", excluding: .allGroups)
      else { return .throwing(typeName: nil) }
    let typeName = suffix[typeStartIndex..<typeEndIndex]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return .throwing(typeName: typeName.isEmpty ? nil : typeName)
  }
}

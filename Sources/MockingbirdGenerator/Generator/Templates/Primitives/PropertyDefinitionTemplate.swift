import Foundation

struct PropertyDefinitionTemplate: Template {
  enum AccessorType {
    case getter, setter
    var keyword: String {
      switch self {
      case .getter: return "get"
      case .setter: return "set"
      }
    }
  }
  
  let type: AccessorType
  let effectSpecifiers: EffectSpecifiers
  let body: String
  
  init(type: AccessorType, effectSpecifiers: EffectSpecifiers = .none, body: String) {
    self.type = type
    self.effectSpecifiers = effectSpecifiers
    self.body = body
  }
  
  func render() -> String {
    return type.keyword + effectSpecifiers.declaration(allowRethrows: false) + " " + BlockTemplate(body: body).render()
  }
}

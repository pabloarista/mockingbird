import Foundation

struct NominalTypeDefinitionTemplate: Template {
  let attributes: [String]
  let declaration: String
  let genericTypes: [String]
  let genericConstraints: [String]
  let inheritedTypes: [String]
  let body: String
  
  init(attributes: [String] = [],
       declaration: String,
       genericTypes: [String] = [],
       genericConstraints: [String] = [],
       inheritedTypes: [String] = [],
       body: String) {
    self.attributes = attributes
    self.declaration = declaration
    self.genericTypes = genericTypes
    self.genericConstraints = genericConstraints
    self.inheritedTypes = inheritedTypes
    self.body = body
  }
  
  func render() -> String {
    let genericTypesString = genericTypes.isEmpty ? "" : "<\(separated: genericTypes)>"
    let genericConstraintsString = genericConstraints.isEmpty ? "" :
      " where \(separated: genericConstraints)"
    let inheritedTypesString = String(list: inheritedTypes)
    return String(lines: [
      attributes.filter({ !$0.isEmpty }).joined(separator: " "),
      declaration + genericTypesString
        + (!inheritedTypes.isEmpty ? ": " : "")
        + inheritedTypesString + genericConstraintsString + " "
        + BlockTemplate(body: body).render(),
    ])
  }
}

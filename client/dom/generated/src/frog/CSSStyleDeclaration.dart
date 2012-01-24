
class CSSStyleDeclarationJS implements CSSStyleDeclaration native "*CSSStyleDeclaration" {

  String get cssText() native "return this.cssText;";

  void set cssText(String value) native "this.cssText = value;";

  int get length() native "return this.length;";

  CSSRuleJS get parentRule() native "return this.parentRule;";

  CSSValueJS getPropertyCSSValue(String propertyName) native;

  String getPropertyPriority(String propertyName) native;

  String getPropertyShorthand(String propertyName) native;

  String getPropertyValue(String propertyName) native;

  bool isPropertyImplicit(String propertyName) native;

  String item(int index) native;

  String removeProperty(String propertyName) native;

  void setProperty(String propertyName, String value, [String priority = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

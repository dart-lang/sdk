
class _CSSStyleDeclarationJs extends _DOMTypeJs implements CSSStyleDeclaration native "*CSSStyleDeclaration" {

  String cssText;

  final int length;

  final _CSSRuleJs parentRule;

  _CSSValueJs getPropertyCSSValue(String propertyName) native;

  String getPropertyPriority(String propertyName) native;

  String getPropertyShorthand(String propertyName) native;

  String getPropertyValue(String propertyName) native;

  bool isPropertyImplicit(String propertyName) native;

  String item(int index) native;

  String removeProperty(String propertyName) native;

  void setProperty(String propertyName, String value, [String priority = null]) native;
}

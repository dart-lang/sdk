
class CSSValue native "*CSSValue" {

  static final int CSS_CUSTOM = 3;

  static final int CSS_INHERIT = 0;

  static final int CSS_PRIMITIVE_VALUE = 1;

  static final int CSS_VALUE_LIST = 2;

  String cssText;

  int cssValueType;

  var dartObjectLocalStorage;

  String get typeName() native;
}

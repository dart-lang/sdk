
class SVGException native "*SVGException" {

  static final int SVG_INVALID_VALUE_ERR = 1;

  static final int SVG_MATRIX_NOT_INVERTABLE = 2;

  static final int SVG_WRONG_TYPE_ERR = 0;

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

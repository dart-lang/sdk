
class _SVGExceptionJs extends _DOMTypeJs implements SVGException native "*SVGException" {

  static final int SVG_INVALID_VALUE_ERR = 1;

  static final int SVG_MATRIX_NOT_INVERTABLE = 2;

  static final int SVG_WRONG_TYPE_ERR = 0;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

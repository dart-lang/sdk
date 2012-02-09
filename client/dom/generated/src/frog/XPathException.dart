
class _XPathExceptionJs extends _DOMTypeJs implements XPathException native "*XPathException" {

  static final int INVALID_EXPRESSION_ERR = 51;

  static final int TYPE_ERR = 52;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

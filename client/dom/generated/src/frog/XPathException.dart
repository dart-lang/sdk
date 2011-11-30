
class XPathException native "*XPathException" {

  static final int INVALID_EXPRESSION_ERR = 51;

  static final int TYPE_ERR = 52;

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

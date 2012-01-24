
class XPathExceptionJS implements XPathException native "*XPathException" {

  static final int INVALID_EXPRESSION_ERR = 51;

  static final int TYPE_ERR = 52;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

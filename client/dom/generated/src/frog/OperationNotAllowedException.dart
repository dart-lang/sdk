
class OperationNotAllowedException native "*OperationNotAllowedException" {

  static final int NOT_ALLOWED_ERR = 1;

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

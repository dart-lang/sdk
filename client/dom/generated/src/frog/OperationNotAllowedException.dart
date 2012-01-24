
class OperationNotAllowedExceptionJS implements OperationNotAllowedException native "*OperationNotAllowedException" {

  static final int NOT_ALLOWED_ERR = 1;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

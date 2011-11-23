
class SQLError native "*SQLError" {

  int code;

  String message;

  var dartObjectLocalStorage;

  String get typeName() native;
}

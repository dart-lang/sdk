
class SQLException native "SQLException" {

  int code;

  String message;

  var dartObjectLocalStorage;

  String get typeName() native;
}


class PositionError native "*PositionError" {

  static final int PERMISSION_DENIED = 1;

  static final int POSITION_UNAVAILABLE = 2;

  static final int TIMEOUT = 3;

  int code;

  String message;

  var dartObjectLocalStorage;

  String get typeName() native;
}

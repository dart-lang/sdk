
class PositionErrorJs extends DOMTypeJs implements PositionError native "*PositionError" {

  static final int PERMISSION_DENIED = 1;

  static final int POSITION_UNAVAILABLE = 2;

  static final int TIMEOUT = 3;

  int get code() native "return this.code;";

  String get message() native "return this.message;";
}


class SQLException native "*SQLException" {

  static final int CONSTRAINT_ERR = 6;

  static final int DATABASE_ERR = 1;

  static final int QUOTA_ERR = 4;

  static final int SYNTAX_ERR = 5;

  static final int TIMEOUT_ERR = 7;

  static final int TOO_LARGE_ERR = 3;

  static final int UNKNOWN_ERR = 0;

  static final int VERSION_ERR = 2;

  int code;

  String message;

  var dartObjectLocalStorage;

  String get typeName() native;
}

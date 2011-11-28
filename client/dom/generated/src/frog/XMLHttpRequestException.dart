
class XMLHttpRequestException native "*XMLHttpRequestException" {

  static final int ABORT_ERR = 102;

  static final int NETWORK_ERR = 101;

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

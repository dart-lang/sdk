
class _XMLHttpRequestExceptionImpl implements XMLHttpRequestException native "*XMLHttpRequestException" {

  static final int ABORT_ERR = 102;

  static final int NETWORK_ERR = 101;

  final int code;

  final String message;

  final String name;

  String toString() native;
}


class _EventExceptionJs extends _DOMTypeJs implements EventException native "*EventException" {

  static final int DISPATCH_REQUEST_ERR = 1;

  static final int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

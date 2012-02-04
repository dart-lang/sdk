
class _OperationNotAllowedExceptionJs extends _DOMTypeJs implements OperationNotAllowedException native "*OperationNotAllowedException" {

  static final int NOT_ALLOWED_ERR = 1;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

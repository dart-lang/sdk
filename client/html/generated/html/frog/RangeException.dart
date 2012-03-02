
class _RangeExceptionImpl implements RangeException native "*RangeException" {

  static final int BAD_BOUNDARYPOINTS_ERR = 1;

  static final int INVALID_NODE_TYPE_ERR = 2;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

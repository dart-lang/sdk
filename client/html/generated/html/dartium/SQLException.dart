
class _SQLExceptionImpl extends _DOMTypeBase implements SQLException {
  _SQLExceptionImpl._wrap(ptr) : super._wrap(ptr);

  int get code() => _wrap(_ptr.code);

  String get message() => _wrap(_ptr.message);
}

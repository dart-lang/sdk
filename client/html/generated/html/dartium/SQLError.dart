
class _SQLErrorImpl extends _DOMTypeBase implements SQLError {
  _SQLErrorImpl._wrap(ptr) : super._wrap(ptr);

  int get code() => _wrap(_ptr.code);

  String get message() => _wrap(_ptr.message);
}

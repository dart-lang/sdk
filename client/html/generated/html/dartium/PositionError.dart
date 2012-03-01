
class _PositionErrorImpl extends _DOMTypeBase implements PositionError {
  _PositionErrorImpl._wrap(ptr) : super._wrap(ptr);

  int get code() => _wrap(_ptr.code);

  String get message() => _wrap(_ptr.message);
}

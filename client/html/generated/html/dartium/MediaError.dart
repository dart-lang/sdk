
class _MediaErrorImpl extends _DOMTypeBase implements MediaError {
  _MediaErrorImpl._wrap(ptr) : super._wrap(ptr);

  int get code() => _wrap(_ptr.code);
}


class _FileErrorImpl extends _DOMTypeBase implements FileError {
  _FileErrorImpl._wrap(ptr) : super._wrap(ptr);

  int get code() => _wrap(_ptr.code);
}

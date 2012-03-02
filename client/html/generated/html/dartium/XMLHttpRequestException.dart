
class _XMLHttpRequestExceptionImpl extends _DOMTypeBase implements XMLHttpRequestException {
  _XMLHttpRequestExceptionImpl._wrap(ptr) : super._wrap(ptr);

  int get code() => _wrap(_ptr.code);

  String get message() => _wrap(_ptr.message);

  String get name() => _wrap(_ptr.name);

  String toString() {
    return _wrap(_ptr.toString());
  }
}

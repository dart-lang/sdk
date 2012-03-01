
class _ErrorEventImpl extends _EventImpl implements ErrorEvent {
  _ErrorEventImpl._wrap(ptr) : super._wrap(ptr);

  String get filename() => _wrap(_ptr.filename);

  int get lineno() => _wrap(_ptr.lineno);

  String get message() => _wrap(_ptr.message);
}

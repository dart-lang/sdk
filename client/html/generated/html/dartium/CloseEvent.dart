
class _CloseEventImpl extends _EventImpl implements CloseEvent {
  _CloseEventImpl._wrap(ptr) : super._wrap(ptr);

  int get code() => _wrap(_ptr.code);

  String get reason() => _wrap(_ptr.reason);

  bool get wasClean() => _wrap(_ptr.wasClean);
}

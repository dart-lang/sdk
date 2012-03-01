
class _ModElementImpl extends _ElementImpl implements ModElement {
  _ModElementImpl._wrap(ptr) : super._wrap(ptr);

  String get cite() => _wrap(_ptr.cite);

  void set cite(String value) { _ptr.cite = _unwrap(value); }

  String get dateTime() => _wrap(_ptr.dateTime);

  void set dateTime(String value) { _ptr.dateTime = _unwrap(value); }
}

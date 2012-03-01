
class _MediaQueryListImpl extends _DOMTypeBase implements MediaQueryList {
  _MediaQueryListImpl._wrap(ptr) : super._wrap(ptr);

  bool get matches() => _wrap(_ptr.matches);

  String get media() => _wrap(_ptr.media);

  void addListener(MediaQueryListListener listener) {
    _ptr.addListener(_unwrap(listener));
    return;
  }

  void removeListener(MediaQueryListListener listener) {
    _ptr.removeListener(_unwrap(listener));
    return;
  }
}

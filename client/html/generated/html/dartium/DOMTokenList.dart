
class _DOMTokenListImpl extends _DOMTypeBase implements DOMTokenList {
  _DOMTokenListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  void add(String token) {
    _ptr.add(_unwrap(token));
    return;
  }

  bool contains(String token) {
    return _wrap(_ptr.contains(_unwrap(token)));
  }

  String item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }

  void remove(String token) {
    _ptr.remove(_unwrap(token));
    return;
  }

  String toString() {
    return _wrap(_ptr.toString());
  }

  bool toggle(String token) {
    return _wrap(_ptr.toggle(_unwrap(token)));
  }
}

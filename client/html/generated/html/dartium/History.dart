
class _HistoryImpl extends _DOMTypeBase implements History {
  _HistoryImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  Dynamic get state() => _wrap(_ptr.state);

  void back() {
    _ptr.back();
    return;
  }

  void forward() {
    _ptr.forward();
    return;
  }

  void go(int distance) {
    _ptr.go(_unwrap(distance));
    return;
  }

  void pushState(Object data, String title, [String url = null]) {
    if (url === null) {
      _ptr.pushState(_unwrap(data), _unwrap(title));
      return;
    } else {
      _ptr.pushState(_unwrap(data), _unwrap(title), _unwrap(url));
      return;
    }
  }

  void replaceState(Object data, String title, [String url = null]) {
    if (url === null) {
      _ptr.replaceState(_unwrap(data), _unwrap(title));
      return;
    } else {
      _ptr.replaceState(_unwrap(data), _unwrap(title), _unwrap(url));
      return;
    }
  }
}


class _StorageImpl extends _DOMTypeBase implements Storage {
  _StorageImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  void clear() {
    _ptr.clear();
    return;
  }

  String getItem(String key) {
    return _wrap(_ptr.getItem(_unwrap(key)));
  }

  String key(int index) {
    return _wrap(_ptr.key(_unwrap(index)));
  }

  void removeItem(String key) {
    _ptr.removeItem(_unwrap(key));
    return;
  }

  void setItem(String key, String data) {
    _ptr.setItem(_unwrap(key), _unwrap(data));
    return;
  }
}

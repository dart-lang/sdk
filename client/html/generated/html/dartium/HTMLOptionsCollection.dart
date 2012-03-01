
class _HTMLOptionsCollectionImpl extends _HTMLCollectionImpl implements HTMLOptionsCollection {
  _HTMLOptionsCollectionImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  void set length(int value) { _ptr.length = _unwrap(value); }

  int get selectedIndex() => _wrap(_ptr.selectedIndex);

  void set selectedIndex(int value) { _ptr.selectedIndex = _unwrap(value); }

  void remove(int index) {
    _ptr.remove(_unwrap(index));
    return;
  }
}

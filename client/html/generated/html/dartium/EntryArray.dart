
class _EntryArrayImpl extends _DOMTypeBase implements EntryArray {
  _EntryArrayImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  Entry item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}

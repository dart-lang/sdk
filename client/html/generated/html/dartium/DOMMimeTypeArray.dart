
class _DOMMimeTypeArrayImpl extends _DOMTypeBase implements DOMMimeTypeArray {
  _DOMMimeTypeArrayImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  DOMMimeType item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }

  DOMMimeType namedItem(String name) {
    return _wrap(_ptr.namedItem(_unwrap(name)));
  }
}

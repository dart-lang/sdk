
class _HTMLAllCollectionImpl extends _DOMTypeBase implements HTMLAllCollection {
  _HTMLAllCollectionImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  Node item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }

  Node namedItem(String name) {
    return _wrap(_ptr.namedItem(_unwrap(name)));
  }

  NodeList tags(String name) {
    return _wrap(_ptr.tags(_unwrap(name)));
  }
}

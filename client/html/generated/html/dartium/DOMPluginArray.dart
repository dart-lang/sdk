
class _DOMPluginArrayImpl extends _DOMTypeBase implements DOMPluginArray {
  _DOMPluginArrayImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  DOMPlugin item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }

  DOMPlugin namedItem(String name) {
    return _wrap(_ptr.namedItem(_unwrap(name)));
  }

  void refresh(bool reload) {
    _ptr.refresh(_unwrap(reload));
    return;
  }
}

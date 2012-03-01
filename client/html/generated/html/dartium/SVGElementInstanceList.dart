
class _SVGElementInstanceListImpl extends _DOMTypeBase implements SVGElementInstanceList {
  _SVGElementInstanceListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  SVGElementInstance item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}

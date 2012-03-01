
class _SQLResultSetRowListImpl extends _DOMTypeBase implements SQLResultSetRowList {
  _SQLResultSetRowListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  Object item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}

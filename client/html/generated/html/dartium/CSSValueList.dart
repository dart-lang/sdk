
class _CSSValueListImpl extends _CSSValueImpl implements CSSValueList {
  _CSSValueListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  CSSValue item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}

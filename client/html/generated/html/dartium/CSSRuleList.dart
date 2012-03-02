
class _CSSRuleListImpl extends _DOMTypeBase implements CSSRuleList {
  _CSSRuleListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  CSSRule item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}


class _CSSPageRuleImpl extends _CSSRuleImpl implements CSSPageRule {
  _CSSPageRuleImpl._wrap(ptr) : super._wrap(ptr);

  String get selectorText() => _wrap(_ptr.selectorText);

  void set selectorText(String value) { _ptr.selectorText = _unwrap(value); }

  CSSStyleDeclaration get style() => _wrap(_ptr.style);
}

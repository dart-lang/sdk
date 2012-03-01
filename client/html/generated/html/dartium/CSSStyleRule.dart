
class _CSSStyleRuleImpl extends _CSSRuleImpl implements CSSStyleRule {
  _CSSStyleRuleImpl._wrap(ptr) : super._wrap(ptr);

  String get selectorText() => _wrap(_ptr.selectorText);

  void set selectorText(String value) { _ptr.selectorText = _unwrap(value); }

  CSSStyleDeclaration get style() => _wrap(_ptr.style);
}

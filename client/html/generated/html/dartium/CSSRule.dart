
class _CSSRuleImpl extends _DOMTypeBase implements CSSRule {
  _CSSRuleImpl._wrap(ptr) : super._wrap(ptr);

  String get cssText() => _wrap(_ptr.cssText);

  void set cssText(String value) { _ptr.cssText = _unwrap(value); }

  CSSRule get parentRule() => _wrap(_ptr.parentRule);

  CSSStyleSheet get parentStyleSheet() => _wrap(_ptr.parentStyleSheet);

  int get type() => _wrap(_ptr.type);
}


class _CSSKeyframeRuleImpl extends _CSSRuleImpl implements CSSKeyframeRule {
  _CSSKeyframeRuleImpl._wrap(ptr) : super._wrap(ptr);

  String get keyText() => _wrap(_ptr.keyText);

  void set keyText(String value) { _ptr.keyText = _unwrap(value); }

  CSSStyleDeclaration get style() => _wrap(_ptr.style);
}

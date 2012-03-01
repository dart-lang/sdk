
class _CSSFontFaceRuleImpl extends _CSSRuleImpl implements CSSFontFaceRule {
  _CSSFontFaceRuleImpl._wrap(ptr) : super._wrap(ptr);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);
}

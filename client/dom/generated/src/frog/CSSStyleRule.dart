
class _CSSStyleRuleJs extends _CSSRuleJs implements CSSStyleRule native "*CSSStyleRule" {

  String get selectorText() native "return this.selectorText;";

  void set selectorText(String value) native "this.selectorText = value;";

  _CSSStyleDeclarationJs get style() native "return this.style;";
}

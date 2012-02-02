
class _CSSPageRuleJs extends _CSSRuleJs implements CSSPageRule native "*CSSPageRule" {

  String get selectorText() native "return this.selectorText;";

  void set selectorText(String value) native "this.selectorText = value;";

  _CSSStyleDeclarationJs get style() native "return this.style;";
}

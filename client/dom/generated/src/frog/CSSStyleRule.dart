
class CSSStyleRuleJs extends CSSRuleJs implements CSSStyleRule native "*CSSStyleRule" {

  String get selectorText() native "return this.selectorText;";

  void set selectorText(String value) native "this.selectorText = value;";

  CSSStyleDeclarationJs get style() native "return this.style;";
}

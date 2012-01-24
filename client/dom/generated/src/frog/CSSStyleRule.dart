
class CSSStyleRuleJS extends CSSRuleJS implements CSSStyleRule native "*CSSStyleRule" {

  String get selectorText() native "return this.selectorText;";

  void set selectorText(String value) native "this.selectorText = value;";

  CSSStyleDeclarationJS get style() native "return this.style;";
}

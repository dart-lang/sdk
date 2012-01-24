
class CSSPageRuleJS extends CSSRuleJS implements CSSPageRule native "*CSSPageRule" {

  String get selectorText() native "return this.selectorText;";

  void set selectorText(String value) native "this.selectorText = value;";

  CSSStyleDeclarationJS get style() native "return this.style;";
}

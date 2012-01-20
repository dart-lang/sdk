
class CSSPageRule extends CSSRule native "*CSSPageRule" {

  String get selectorText() native "return this.selectorText;";

  void set selectorText(String value) native "this.selectorText = value;";

  CSSStyleDeclaration get style() native "return this.style;";
}

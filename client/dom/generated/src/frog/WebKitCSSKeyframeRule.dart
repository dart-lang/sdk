
class WebKitCSSKeyframeRuleJS extends CSSRuleJS implements WebKitCSSKeyframeRule native "*WebKitCSSKeyframeRule" {

  String get keyText() native "return this.keyText;";

  void set keyText(String value) native "this.keyText = value;";

  CSSStyleDeclarationJS get style() native "return this.style;";
}

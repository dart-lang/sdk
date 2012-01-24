
class WebKitCSSKeyframeRuleJs extends CSSRuleJs implements WebKitCSSKeyframeRule native "*WebKitCSSKeyframeRule" {

  String get keyText() native "return this.keyText;";

  void set keyText(String value) native "this.keyText = value;";

  CSSStyleDeclarationJs get style() native "return this.style;";
}

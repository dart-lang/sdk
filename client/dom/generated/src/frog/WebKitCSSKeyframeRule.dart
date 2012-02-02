
class _WebKitCSSKeyframeRuleJs extends _CSSRuleJs implements WebKitCSSKeyframeRule native "*WebKitCSSKeyframeRule" {

  String get keyText() native "return this.keyText;";

  void set keyText(String value) native "this.keyText = value;";

  _CSSStyleDeclarationJs get style() native "return this.style;";
}

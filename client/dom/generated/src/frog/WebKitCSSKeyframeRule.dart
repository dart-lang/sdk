
class WebKitCSSKeyframeRule extends CSSRule native "*WebKitCSSKeyframeRule" {

  String get keyText() native "return this.keyText;";

  void set keyText(String value) native "this.keyText = value;";

  CSSStyleDeclaration get style() native "return this.style;";
}

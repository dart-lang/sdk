
class CSSCharsetRuleJs extends CSSRuleJs implements CSSCharsetRule native "*CSSCharsetRule" {

  String get encoding() native "return this.encoding;";

  void set encoding(String value) native "this.encoding = value;";
}

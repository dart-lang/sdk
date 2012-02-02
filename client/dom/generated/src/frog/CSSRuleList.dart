
class _CSSRuleListJs extends _DOMTypeJs implements CSSRuleList native "*CSSRuleList" {

  int get length() native "return this.length;";

  _CSSRuleJs item(int index) native;
}


class CSSRuleListJs extends DOMTypeJs implements CSSRuleList native "*CSSRuleList" {

  int get length() native "return this.length;";

  CSSRuleJs item(int index) native;
}

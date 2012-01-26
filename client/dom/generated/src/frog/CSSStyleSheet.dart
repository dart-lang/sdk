
class CSSStyleSheetJs extends StyleSheetJs implements CSSStyleSheet native "*CSSStyleSheet" {

  CSSRuleListJs get cssRules() native "return this.cssRules;";

  CSSRuleJs get ownerRule() native "return this.ownerRule;";

  CSSRuleListJs get rules() native "return this.rules;";

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

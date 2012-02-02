
class _CSSStyleSheetJs extends _StyleSheetJs implements CSSStyleSheet native "*CSSStyleSheet" {

  _CSSRuleListJs get cssRules() native "return this.cssRules;";

  _CSSRuleJs get ownerRule() native "return this.ownerRule;";

  _CSSRuleListJs get rules() native "return this.rules;";

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

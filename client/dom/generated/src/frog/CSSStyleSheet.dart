
class CSSStyleSheetJS extends StyleSheetJS implements CSSStyleSheet native "*CSSStyleSheet" {

  CSSRuleListJS get cssRules() native "return this.cssRules;";

  CSSRuleJS get ownerRule() native "return this.ownerRule;";

  CSSRuleListJS get rules() native "return this.rules;";

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

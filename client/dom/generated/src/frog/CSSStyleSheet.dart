
class CSSStyleSheet extends StyleSheet native "*CSSStyleSheet" {

  CSSRuleList get cssRules() native "return this.cssRules;";

  CSSRule get ownerRule() native "return this.ownerRule;";

  CSSRuleList get rules() native "return this.rules;";

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

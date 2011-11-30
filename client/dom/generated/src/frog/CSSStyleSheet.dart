
class CSSStyleSheet extends StyleSheet native "*CSSStyleSheet" {

  CSSRuleList cssRules;

  CSSRule ownerRule;

  CSSRuleList rules;

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

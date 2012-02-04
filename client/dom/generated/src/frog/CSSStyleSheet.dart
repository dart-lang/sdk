
class _CSSStyleSheetJs extends _StyleSheetJs implements CSSStyleSheet native "*CSSStyleSheet" {

  final _CSSRuleListJs cssRules;

  final _CSSRuleJs ownerRule;

  final _CSSRuleListJs rules;

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

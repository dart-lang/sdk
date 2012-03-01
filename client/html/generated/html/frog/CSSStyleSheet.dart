
class _CSSStyleSheetImpl extends _StyleSheetImpl implements CSSStyleSheet native "*CSSStyleSheet" {

  final _CSSRuleListImpl cssRules;

  final _CSSRuleImpl ownerRule;

  final _CSSRuleListImpl rules;

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

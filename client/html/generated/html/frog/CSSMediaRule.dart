
class _CSSMediaRuleImpl extends _CSSRuleImpl implements CSSMediaRule native "*CSSMediaRule" {

  final _CSSRuleListImpl cssRules;

  final _MediaListImpl media;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

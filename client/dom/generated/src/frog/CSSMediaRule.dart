
class _CSSMediaRuleJs extends _CSSRuleJs implements CSSMediaRule native "*CSSMediaRule" {

  final _CSSRuleListJs cssRules;

  final _MediaListJs media;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

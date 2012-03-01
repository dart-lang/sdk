
class _CSSKeyframesRuleImpl extends _CSSRuleImpl implements CSSKeyframesRule native "*WebKitCSSKeyframesRule" {

  final _CSSRuleListImpl cssRules;

  String name;

  void deleteRule(String key) native;

  _CSSKeyframeRuleImpl findRule(String key) native;

  void insertRule(String rule) native;
}

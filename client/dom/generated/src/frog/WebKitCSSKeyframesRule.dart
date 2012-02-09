
class _WebKitCSSKeyframesRuleJs extends _CSSRuleJs implements WebKitCSSKeyframesRule native "*WebKitCSSKeyframesRule" {

  final _CSSRuleListJs cssRules;

  String name;

  void deleteRule(String key) native;

  _WebKitCSSKeyframeRuleJs findRule(String key) native;

  void insertRule(String rule) native;
}

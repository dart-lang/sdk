
class WebKitCSSKeyframesRule extends CSSRule native "*WebKitCSSKeyframesRule" {

  CSSRuleList cssRules;

  String name;

  void deleteRule(String key) native;

  WebKitCSSKeyframeRule findRule(String key) native;

  void insertRule(String rule) native;
}

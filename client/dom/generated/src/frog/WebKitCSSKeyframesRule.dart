
class WebKitCSSKeyframesRuleJS extends CSSRuleJS implements WebKitCSSKeyframesRule native "*WebKitCSSKeyframesRule" {

  CSSRuleListJS get cssRules() native "return this.cssRules;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  void deleteRule(String key) native;

  WebKitCSSKeyframeRuleJS findRule(String key) native;

  void insertRule(String rule) native;
}

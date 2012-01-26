
class WebKitCSSKeyframesRuleJs extends CSSRuleJs implements WebKitCSSKeyframesRule native "*WebKitCSSKeyframesRule" {

  CSSRuleListJs get cssRules() native "return this.cssRules;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  void deleteRule(String key) native;

  WebKitCSSKeyframeRuleJs findRule(String key) native;

  void insertRule(String rule) native;
}


class _CSSMediaRuleJs extends _CSSRuleJs implements CSSMediaRule native "*CSSMediaRule" {

  _CSSRuleListJs get cssRules() native "return this.cssRules;";

  _MediaListJs get media() native "return this.media;";

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

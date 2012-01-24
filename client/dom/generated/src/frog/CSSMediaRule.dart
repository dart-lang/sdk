
class CSSMediaRuleJs extends CSSRuleJs implements CSSMediaRule native "*CSSMediaRule" {

  CSSRuleListJs get cssRules() native "return this.cssRules;";

  MediaListJs get media() native "return this.media;";

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

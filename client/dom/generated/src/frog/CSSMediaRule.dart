
class CSSMediaRuleJS extends CSSRuleJS implements CSSMediaRule native "*CSSMediaRule" {

  CSSRuleListJS get cssRules() native "return this.cssRules;";

  MediaListJS get media() native "return this.media;";

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

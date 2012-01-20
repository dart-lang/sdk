
class CSSMediaRule extends CSSRule native "*CSSMediaRule" {

  CSSRuleList get cssRules() native "return this.cssRules;";

  MediaList get media() native "return this.media;";

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

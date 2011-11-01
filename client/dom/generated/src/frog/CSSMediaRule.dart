
class CSSMediaRule extends CSSRule native "CSSMediaRule" {

  CSSRuleList cssRules;

  MediaList media;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

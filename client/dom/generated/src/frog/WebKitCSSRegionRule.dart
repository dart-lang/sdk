
class WebKitCSSRegionRuleJs extends CSSRuleJs implements WebKitCSSRegionRule native "*WebKitCSSRegionRule" {

  CSSRuleListJs get cssRules() native "return this.cssRules;";
}

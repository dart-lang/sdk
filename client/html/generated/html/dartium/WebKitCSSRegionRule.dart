
class _WebKitCSSRegionRuleImpl extends _CSSRuleImpl implements WebKitCSSRegionRule {
  _WebKitCSSRegionRuleImpl._wrap(ptr) : super._wrap(ptr);

  CSSRuleList get cssRules() => _wrap(_ptr.cssRules);
}


class _CSSStyleSheetImpl extends _StyleSheetImpl implements CSSStyleSheet {
  _CSSStyleSheetImpl._wrap(ptr) : super._wrap(ptr);

  CSSRuleList get cssRules() => _wrap(_ptr.cssRules);

  CSSRule get ownerRule() => _wrap(_ptr.ownerRule);

  CSSRuleList get rules() => _wrap(_ptr.rules);

  int addRule(String selector, String style, [int index = null]) {
    if (index === null) {
      return _wrap(_ptr.addRule(_unwrap(selector), _unwrap(style)));
    } else {
      return _wrap(_ptr.addRule(_unwrap(selector), _unwrap(style), _unwrap(index)));
    }
  }

  void deleteRule(int index) {
    _ptr.deleteRule(_unwrap(index));
    return;
  }

  int insertRule(String rule, int index) {
    return _wrap(_ptr.insertRule(_unwrap(rule), _unwrap(index)));
  }

  void removeRule(int index) {
    _ptr.removeRule(_unwrap(index));
    return;
  }
}

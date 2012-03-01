
class _CSSKeyframesRuleImpl extends _CSSRuleImpl implements CSSKeyframesRule {
  _CSSKeyframesRuleImpl._wrap(ptr) : super._wrap(ptr);

  CSSRuleList get cssRules() => _wrap(_ptr.cssRules);

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  void deleteRule(String key) {
    _ptr.deleteRule(_unwrap(key));
    return;
  }

  CSSKeyframeRule findRule(String key) {
    return _wrap(_ptr.findRule(_unwrap(key)));
  }

  void insertRule(String rule) {
    _ptr.insertRule(_unwrap(rule));
    return;
  }
}

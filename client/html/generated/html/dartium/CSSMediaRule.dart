
class _CSSMediaRuleImpl extends _CSSRuleImpl implements CSSMediaRule {
  _CSSMediaRuleImpl._wrap(ptr) : super._wrap(ptr);

  CSSRuleList get cssRules() => _wrap(_ptr.cssRules);

  MediaList get media() => _wrap(_ptr.media);

  void deleteRule(int index) {
    _ptr.deleteRule(_unwrap(index));
    return;
  }

  int insertRule(String rule, int index) {
    return _wrap(_ptr.insertRule(_unwrap(rule), _unwrap(index)));
  }
}

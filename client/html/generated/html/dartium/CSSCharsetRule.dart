
class _CSSCharsetRuleImpl extends _CSSRuleImpl implements CSSCharsetRule {
  _CSSCharsetRuleImpl._wrap(ptr) : super._wrap(ptr);

  String get encoding() => _wrap(_ptr.encoding);

  void set encoding(String value) { _ptr.encoding = _unwrap(value); }
}

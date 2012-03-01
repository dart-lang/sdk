
class _CSSImportRuleImpl extends _CSSRuleImpl implements CSSImportRule {
  _CSSImportRuleImpl._wrap(ptr) : super._wrap(ptr);

  String get href() => _wrap(_ptr.href);

  MediaList get media() => _wrap(_ptr.media);

  CSSStyleSheet get styleSheet() => _wrap(_ptr.styleSheet);
}

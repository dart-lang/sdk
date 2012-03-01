
class _StyleSheetImpl extends _DOMTypeBase implements StyleSheet {
  _StyleSheetImpl._wrap(ptr) : super._wrap(ptr);

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  String get href() => _wrap(_ptr.href);

  MediaList get media() => _wrap(_ptr.media);

  Node get ownerNode() => _wrap(_ptr.ownerNode);

  StyleSheet get parentStyleSheet() => _wrap(_ptr.parentStyleSheet);

  String get title() => _wrap(_ptr.title);

  String get type() => _wrap(_ptr.type);
}

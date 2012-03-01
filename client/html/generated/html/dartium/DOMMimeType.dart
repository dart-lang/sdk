
class _DOMMimeTypeImpl extends _DOMTypeBase implements DOMMimeType {
  _DOMMimeTypeImpl._wrap(ptr) : super._wrap(ptr);

  String get description() => _wrap(_ptr.description);

  DOMPlugin get enabledPlugin() => _wrap(_ptr.enabledPlugin);

  String get suffixes() => _wrap(_ptr.suffixes);

  String get type() => _wrap(_ptr.type);
}

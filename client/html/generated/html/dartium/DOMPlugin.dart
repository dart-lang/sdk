
class _DOMPluginImpl extends _DOMTypeBase implements DOMPlugin {
  _DOMPluginImpl._wrap(ptr) : super._wrap(ptr);

  String get description() => _wrap(_ptr.description);

  String get filename() => _wrap(_ptr.filename);

  int get length() => _wrap(_ptr.length);

  String get name() => _wrap(_ptr.name);

  DOMMimeType item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }

  DOMMimeType namedItem(String name) {
    return _wrap(_ptr.namedItem(_unwrap(name)));
  }
}

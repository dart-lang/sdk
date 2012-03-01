
class _SVGTestsImpl extends _DOMTypeBase implements SVGTests {
  _SVGTestsImpl._wrap(ptr) : super._wrap(ptr);

  SVGStringList get requiredExtensions() => _wrap(_ptr.requiredExtensions);

  SVGStringList get requiredFeatures() => _wrap(_ptr.requiredFeatures);

  SVGStringList get systemLanguage() => _wrap(_ptr.systemLanguage);

  bool hasExtension(String extension) {
    return _wrap(_ptr.hasExtension(_unwrap(extension)));
  }
}

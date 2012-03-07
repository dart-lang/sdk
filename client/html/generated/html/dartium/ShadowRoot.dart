
class _ShadowRootImpl extends _DocumentFragmentImpl implements ShadowRoot {
  _ShadowRootImpl._wrap(ptr) : super._wrap(ptr);

  Element get host() => _wrap(_ptr.host);

  Element getElementById(String elementId) {
    return _wrap(_ptr.getElementById(_unwrap(elementId)));
  }

  NodeList getElementsByClassName(String className) {
    return _wrap(_ptr.getElementsByClassName(_unwrap(className)));
  }

  NodeList getElementsByTagName(String tagName) {
    return _wrap(_ptr.getElementsByTagName(_unwrap(tagName)));
  }

  NodeList getElementsByTagNameNS(String namespaceURI, String localName) {
    return _wrap(_ptr.getElementsByTagNameNS(_unwrap(namespaceURI), _unwrap(localName)));
  }
}

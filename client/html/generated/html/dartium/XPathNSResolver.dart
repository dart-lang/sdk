
class _XPathNSResolverImpl extends _DOMTypeBase implements XPathNSResolver {
  _XPathNSResolverImpl._wrap(ptr) : super._wrap(ptr);

  String lookupNamespaceURI(String prefix) {
    return _wrap(_ptr.lookupNamespaceURI(_unwrap(prefix)));
  }
}

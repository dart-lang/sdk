
class _ShadowRootImpl extends _DocumentFragmentImpl implements ShadowRoot native "*ShadowRoot" {

  final _ElementImpl host;

  String innerHTML;

  _ElementImpl getElementById(String elementId) native;

  _NodeListImpl getElementsByClassName(String className) native;

  _NodeListImpl getElementsByTagName(String tagName) native;

  _NodeListImpl getElementsByTagNameNS(String namespaceURI, String localName) native;
}

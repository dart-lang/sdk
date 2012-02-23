
class _ShadowRootJs extends _DocumentFragmentJs implements ShadowRoot native "*ShadowRoot" {

  final _ElementJs host;

  _ElementJs getElementById(String elementId) native;

  _NodeListJs getElementsByClassName(String className) native;

  _NodeListJs getElementsByTagName(String tagName) native;

  _NodeListJs getElementsByTagNameNS(String namespaceURI, String localName) native;
}

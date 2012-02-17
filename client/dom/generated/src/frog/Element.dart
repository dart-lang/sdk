
class _ElementJs extends _NodeJs implements Element native "*Element" {

  static final int ALLOW_KEYBOARD_INPUT = 1;

  final int childElementCount;

  final int clientHeight;

  final int clientLeft;

  final int clientTop;

  final int clientWidth;

  final _ElementJs firstElementChild;

  final _ElementJs lastElementChild;

  final _ElementJs nextElementSibling;

  final int offsetHeight;

  final int offsetLeft;

  final _ElementJs offsetParent;

  final int offsetTop;

  final int offsetWidth;

  final _ElementJs previousElementSibling;

  final int scrollHeight;

  int scrollLeft;

  int scrollTop;

  final int scrollWidth;

  final _CSSStyleDeclarationJs style;

  final String tagName;

  final String webkitRegionOverflow;

  void blur() native;

  void focus() native;

  String getAttribute(String name) native;

  String getAttributeNS(String namespaceURI, String localName) native;

  _AttrJs getAttributeNode(String name) native;

  _AttrJs getAttributeNodeNS(String namespaceURI, String localName) native;

  _ClientRectJs getBoundingClientRect() native;

  _ClientRectListJs getClientRects() native;

  _NodeListJs getElementsByClassName(String name) native;

  _NodeListJs getElementsByTagName(String name) native;

  _NodeListJs getElementsByTagNameNS(String namespaceURI, String localName) native;

  bool hasAttribute(String name) native;

  bool hasAttributeNS(String namespaceURI, String localName) native;

  _ElementJs querySelector(String selectors) native;

  _NodeListJs querySelectorAll(String selectors) native;

  void removeAttribute(String name) native;

  void removeAttributeNS(String namespaceURI, String localName) native;

  _AttrJs removeAttributeNode(_AttrJs oldAttr) native;

  void scrollByLines(int lines) native;

  void scrollByPages(int pages) native;

  void scrollIntoView([bool alignWithTop = null]) native;

  void scrollIntoViewIfNeeded([bool centerIfNeeded = null]) native;

  void setAttribute(String name, String value) native;

  void setAttributeNS(String namespaceURI, String qualifiedName, String value) native;

  _AttrJs setAttributeNode(_AttrJs newAttr) native;

  _AttrJs setAttributeNodeNS(_AttrJs newAttr) native;

  bool webkitMatchesSelector(String selectors) native;

  void webkitRequestFullScreen(int flags) native;
}

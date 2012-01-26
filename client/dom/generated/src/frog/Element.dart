
class ElementJs extends NodeJs implements Element native "*Element" {

  static final int ALLOW_KEYBOARD_INPUT = 1;

  int get childElementCount() native "return this.childElementCount;";

  int get clientHeight() native "return this.clientHeight;";

  int get clientLeft() native "return this.clientLeft;";

  int get clientTop() native "return this.clientTop;";

  int get clientWidth() native "return this.clientWidth;";

  ElementJs get firstElementChild() native "return this.firstElementChild;";

  ElementJs get lastElementChild() native "return this.lastElementChild;";

  ElementJs get nextElementSibling() native "return this.nextElementSibling;";

  int get offsetHeight() native "return this.offsetHeight;";

  int get offsetLeft() native "return this.offsetLeft;";

  ElementJs get offsetParent() native "return this.offsetParent;";

  int get offsetTop() native "return this.offsetTop;";

  int get offsetWidth() native "return this.offsetWidth;";

  ElementJs get previousElementSibling() native "return this.previousElementSibling;";

  int get scrollHeight() native "return this.scrollHeight;";

  int get scrollLeft() native "return this.scrollLeft;";

  void set scrollLeft(int value) native "this.scrollLeft = value;";

  int get scrollTop() native "return this.scrollTop;";

  void set scrollTop(int value) native "this.scrollTop = value;";

  int get scrollWidth() native "return this.scrollWidth;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  String get tagName() native "return this.tagName;";

  void blur() native;

  void focus() native;

  String getAttribute(String name) native;

  String getAttributeNS(String namespaceURI, String localName) native;

  AttrJs getAttributeNode(String name) native;

  AttrJs getAttributeNodeNS(String namespaceURI, String localName) native;

  ClientRectJs getBoundingClientRect() native;

  ClientRectListJs getClientRects() native;

  NodeListJs getElementsByClassName(String name) native;

  NodeListJs getElementsByTagName(String name) native;

  NodeListJs getElementsByTagNameNS(String namespaceURI, String localName) native;

  bool hasAttribute(String name) native;

  bool hasAttributeNS(String namespaceURI, String localName) native;

  ElementJs querySelector(String selectors) native;

  NodeListJs querySelectorAll(String selectors) native;

  void removeAttribute(String name) native;

  void removeAttributeNS(String namespaceURI, String localName) native;

  AttrJs removeAttributeNode(AttrJs oldAttr) native;

  void scrollByLines(int lines) native;

  void scrollByPages(int pages) native;

  void scrollIntoView([bool alignWithTop = null]) native;

  void scrollIntoViewIfNeeded([bool centerIfNeeded = null]) native;

  void setAttribute(String name, String value) native;

  void setAttributeNS(String namespaceURI, String qualifiedName, String value) native;

  AttrJs setAttributeNode(AttrJs newAttr) native;

  AttrJs setAttributeNodeNS(AttrJs newAttr) native;

  bool webkitMatchesSelector(String selectors) native;

  void webkitRequestFullScreen(int flags) native;
}

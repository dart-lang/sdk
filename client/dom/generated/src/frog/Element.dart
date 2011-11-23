
class Element extends Node native "*Element" {

  int childElementCount;

  int clientHeight;

  int clientLeft;

  int clientTop;

  int clientWidth;

  Element firstElementChild;

  Element lastElementChild;

  Element nextElementSibling;

  int offsetHeight;

  int offsetLeft;

  Element offsetParent;

  int offsetTop;

  int offsetWidth;

  EventListener onabort;

  EventListener onbeforecopy;

  EventListener onbeforecut;

  EventListener onbeforepaste;

  EventListener onblur;

  EventListener onchange;

  EventListener onclick;

  EventListener oncontextmenu;

  EventListener oncopy;

  EventListener oncut;

  EventListener ondblclick;

  EventListener ondrag;

  EventListener ondragend;

  EventListener ondragenter;

  EventListener ondragleave;

  EventListener ondragover;

  EventListener ondragstart;

  EventListener ondrop;

  EventListener onerror;

  EventListener onfocus;

  EventListener oninput;

  EventListener oninvalid;

  EventListener onkeydown;

  EventListener onkeypress;

  EventListener onkeyup;

  EventListener onload;

  EventListener onmousedown;

  EventListener onmousemove;

  EventListener onmouseout;

  EventListener onmouseover;

  EventListener onmouseup;

  EventListener onmousewheel;

  EventListener onpaste;

  EventListener onreset;

  EventListener onscroll;

  EventListener onsearch;

  EventListener onselect;

  EventListener onselectstart;

  EventListener onsubmit;

  EventListener ontouchcancel;

  EventListener ontouchend;

  EventListener ontouchmove;

  EventListener ontouchstart;

  EventListener onwebkitfullscreenchange;

  Element previousElementSibling;

  int scrollHeight;

  int scrollLeft;

  int scrollTop;

  int scrollWidth;

  CSSStyleDeclaration style;

  String tagName;

  void blur() native;

  void focus() native;

  String getAttribute(String name) native;

  String getAttributeNS(String namespaceURI, String localName) native;

  Attr getAttributeNode(String name) native;

  Attr getAttributeNodeNS(String namespaceURI, String localName) native;

  ClientRect getBoundingClientRect() native;

  ClientRectList getClientRects() native;

  NodeList getElementsByClassName(String name) native;

  NodeList getElementsByTagName(String name) native;

  NodeList getElementsByTagNameNS(String namespaceURI, String localName) native;

  bool hasAttribute(String name) native;

  bool hasAttributeNS(String namespaceURI, String localName) native;

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;

  void removeAttribute(String name) native;

  void removeAttributeNS(String namespaceURI, String localName) native;

  Attr removeAttributeNode(Attr oldAttr) native;

  void scrollByLines(int lines) native;

  void scrollByPages(int pages) native;

  void scrollIntoView([bool alignWithTop = null]) native;

  void scrollIntoViewIfNeeded([bool centerIfNeeded = null]) native;

  void setAttribute(String name, String value) native;

  void setAttributeNS(String namespaceURI, String qualifiedName, String value) native;

  Attr setAttributeNode(Attr newAttr) native;

  Attr setAttributeNodeNS(Attr newAttr) native;

  bool webkitMatchesSelector(String selectors) native;
}

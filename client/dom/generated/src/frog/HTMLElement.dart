
class HTMLElement extends Element native "HTMLElement" {

  HTMLCollection children;

  DOMTokenList classList;

  String className;

  String contentEditable;

  String dir;

  bool draggable;

  bool hidden;

  String id;

  String innerHTML;

  String innerText;

  bool isContentEditable;

  String lang;

  String outerHTML;

  String outerText;

  bool spellcheck;

  int tabIndex;

  String title;

  String webkitdropzone;

  Element insertAdjacentElement(String where, Element element) native;

  void insertAdjacentHTML(String where, String html) native;

  void insertAdjacentText(String where, String text) native;
}

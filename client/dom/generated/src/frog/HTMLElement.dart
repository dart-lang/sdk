
class _HTMLElementJs extends _ElementJs implements HTMLElement native "*HTMLElement" {

  String accessKey;

  final _HTMLCollectionJs children;

  final _DOMTokenListJs classList;

  String className;

  String contentEditable;

  String dir;

  bool draggable;

  bool hidden;

  String id;

  String innerHTML;

  String innerText;

  final bool isContentEditable;

  String lang;

  String outerHTML;

  String outerText;

  bool spellcheck;

  int tabIndex;

  String title;

  bool translate;

  String webkitdropzone;

  void click() native;

  _ElementJs insertAdjacentElement(String where, _ElementJs element) native;

  void insertAdjacentHTML(String where, String html) native;

  void insertAdjacentText(String where, String text) native;
}

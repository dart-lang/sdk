
class HTMLElementJs extends ElementJs implements HTMLElement native "*HTMLElement" {

  String get accessKey() native "return this.accessKey;";

  void set accessKey(String value) native "this.accessKey = value;";

  HTMLCollectionJs get children() native "return this.children;";

  DOMTokenListJs get classList() native "return this.classList;";

  String get className() native "return this.className;";

  void set className(String value) native "this.className = value;";

  String get contentEditable() native "return this.contentEditable;";

  void set contentEditable(String value) native "this.contentEditable = value;";

  String get dir() native "return this.dir;";

  void set dir(String value) native "this.dir = value;";

  bool get draggable() native "return this.draggable;";

  void set draggable(bool value) native "this.draggable = value;";

  bool get hidden() native "return this.hidden;";

  void set hidden(bool value) native "this.hidden = value;";

  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  String get innerHTML() native "return this.innerHTML;";

  void set innerHTML(String value) native "this.innerHTML = value;";

  String get innerText() native "return this.innerText;";

  void set innerText(String value) native "this.innerText = value;";

  bool get isContentEditable() native "return this.isContentEditable;";

  String get itemId() native "return this.itemId;";

  void set itemId(String value) native "this.itemId = value;";

  DOMSettableTokenListJs get itemProp() native "return this.itemProp;";

  DOMSettableTokenListJs get itemRef() native "return this.itemRef;";

  bool get itemScope() native "return this.itemScope;";

  void set itemScope(bool value) native "this.itemScope = value;";

  DOMSettableTokenListJs get itemType() native "return this.itemType;";

  Object get itemValue() native "return this.itemValue;";

  void set itemValue(Object value) native "this.itemValue = value;";

  String get lang() native "return this.lang;";

  void set lang(String value) native "this.lang = value;";

  String get outerHTML() native "return this.outerHTML;";

  void set outerHTML(String value) native "this.outerHTML = value;";

  String get outerText() native "return this.outerText;";

  void set outerText(String value) native "this.outerText = value;";

  bool get spellcheck() native "return this.spellcheck;";

  void set spellcheck(bool value) native "this.spellcheck = value;";

  int get tabIndex() native "return this.tabIndex;";

  void set tabIndex(int value) native "this.tabIndex = value;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  String get webkitdropzone() native "return this.webkitdropzone;";

  void set webkitdropzone(String value) native "this.webkitdropzone = value;";

  ElementJs insertAdjacentElement(String where, ElementJs element) native;

  void insertAdjacentHTML(String where, String html) native;

  void insertAdjacentText(String where, String text) native;
}

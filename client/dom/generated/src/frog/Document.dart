
class Document extends Node native "*Document" {

  String get URL() native "return this.URL;";

  HTMLCollection get anchors() native "return this.anchors;";

  HTMLCollection get applets() native "return this.applets;";

  HTMLElement get body() native "return this.body;";

  void set body(HTMLElement value) native "this.body = value;";

  String get characterSet() native "return this.characterSet;";

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  String get compatMode() native "return this.compatMode;";

  String get cookie() native "return this.cookie;";

  void set cookie(String value) native "this.cookie = value;";

  String get defaultCharset() native "return this.defaultCharset;";

  DOMWindow get defaultView() native "return this.defaultView;";

  DocumentType get doctype() native "return this.doctype;";

  Element get documentElement() native "return this.documentElement;";

  String get documentURI() native "return this.documentURI;";

  void set documentURI(String value) native "this.documentURI = value;";

  String get domain() native "return this.domain;";

  void set domain(String value) native "this.domain = value;";

  HTMLCollection get forms() native "return this.forms;";

  HTMLHeadElement get head() native "return this.head;";

  HTMLCollection get images() native "return this.images;";

  DOMImplementation get implementation() native "return this.implementation;";

  String get inputEncoding() native "return this.inputEncoding;";

  String get lastModified() native "return this.lastModified;";

  HTMLCollection get links() native "return this.links;";

  Location get location() native "return this.location;";

  void set location(Location value) native "this.location = value;";

  String get preferredStylesheetSet() native "return this.preferredStylesheetSet;";

  String get readyState() native "return this.readyState;";

  String get referrer() native "return this.referrer;";

  String get selectedStylesheetSet() native "return this.selectedStylesheetSet;";

  void set selectedStylesheetSet(String value) native "this.selectedStylesheetSet = value;";

  StyleSheetList get styleSheets() native "return this.styleSheets;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  Element get webkitCurrentFullScreenElement() native "return this.webkitCurrentFullScreenElement;";

  bool get webkitFullScreenKeyboardInputAllowed() native "return this.webkitFullScreenKeyboardInputAllowed;";

  bool get webkitHidden() native "return this.webkitHidden;";

  bool get webkitIsFullScreen() native "return this.webkitIsFullScreen;";

  String get webkitVisibilityState() native "return this.webkitVisibilityState;";

  String get xmlEncoding() native "return this.xmlEncoding;";

  bool get xmlStandalone() native "return this.xmlStandalone;";

  void set xmlStandalone(bool value) native "this.xmlStandalone = value;";

  String get xmlVersion() native "return this.xmlVersion;";

  void set xmlVersion(String value) native "this.xmlVersion = value;";

  Node adoptNode(Node source) native;

  Range caretRangeFromPoint(int x, int y) native;

  Attr createAttribute(String name) native;

  Attr createAttributeNS(String namespaceURI, String qualifiedName) native;

  CDATASection createCDATASection(String data) native;

  Comment createComment(String data) native;

  DocumentFragment createDocumentFragment() native;

  Element createElement(String tagName) native;

  Element createElementNS(String namespaceURI, String qualifiedName) native;

  EntityReference createEntityReference(String name) native;

  Event createEvent(String eventType) native;

  XPathExpression createExpression(String expression, XPathNSResolver resolver) native;

  XPathNSResolver createNSResolver(Node nodeResolver) native;

  NodeIterator createNodeIterator(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences) native;

  ProcessingInstruction createProcessingInstruction(String target, String data) native;

  Range createRange() native;

  Text createTextNode(String data) native;

  Touch createTouch(DOMWindow window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native;

  TouchList createTouchList() native;

  TreeWalker createTreeWalker(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences) native;

  Element elementFromPoint(int x, int y) native;

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) native;

  bool execCommand(String command, bool userInterface, String value) native;

  Object getCSSCanvasContext(String contextId, String name, int width, int height) native;

  Element getElementById(String elementId) native;

  NodeList getElementsByClassName(String tagname) native;

  NodeList getElementsByName(String elementName) native;

  NodeList getElementsByTagName(String tagname) native;

  NodeList getElementsByTagNameNS(String namespaceURI, String localName) native;

  CSSStyleDeclaration getOverrideStyle(Element element, String pseudoElement) native;

  DOMSelection getSelection() native;

  Node importNode(Node importedNode, [bool deep = null]) native;

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;

  void webkitCancelFullScreen() native;

  WebKitNamedFlow webkitGetFlowByName(String name) native;
}


class DocumentJS extends NodeJS implements Document native "*Document" {

  String get URL() native "return this.URL;";

  HTMLCollectionJS get anchors() native "return this.anchors;";

  HTMLCollectionJS get applets() native "return this.applets;";

  HTMLElementJS get body() native "return this.body;";

  void set body(HTMLElementJS value) native "this.body = value;";

  String get characterSet() native "return this.characterSet;";

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  String get compatMode() native "return this.compatMode;";

  String get cookie() native "return this.cookie;";

  void set cookie(String value) native "this.cookie = value;";

  String get defaultCharset() native "return this.defaultCharset;";

  DOMWindowJS get defaultView() native "return this.defaultView;";

  DocumentTypeJS get doctype() native "return this.doctype;";

  ElementJS get documentElement() native "return this.documentElement;";

  String get documentURI() native "return this.documentURI;";

  void set documentURI(String value) native "this.documentURI = value;";

  String get domain() native "return this.domain;";

  void set domain(String value) native "this.domain = value;";

  HTMLCollectionJS get forms() native "return this.forms;";

  HTMLHeadElementJS get head() native "return this.head;";

  HTMLCollectionJS get images() native "return this.images;";

  DOMImplementationJS get implementation() native "return this.implementation;";

  String get inputEncoding() native "return this.inputEncoding;";

  String get lastModified() native "return this.lastModified;";

  HTMLCollectionJS get links() native "return this.links;";

  LocationJS get location() native "return this.location;";

  void set location(LocationJS value) native "this.location = value;";

  String get preferredStylesheetSet() native "return this.preferredStylesheetSet;";

  String get readyState() native "return this.readyState;";

  String get referrer() native "return this.referrer;";

  String get selectedStylesheetSet() native "return this.selectedStylesheetSet;";

  void set selectedStylesheetSet(String value) native "this.selectedStylesheetSet = value;";

  StyleSheetListJS get styleSheets() native "return this.styleSheets;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  ElementJS get webkitCurrentFullScreenElement() native "return this.webkitCurrentFullScreenElement;";

  bool get webkitFullScreenKeyboardInputAllowed() native "return this.webkitFullScreenKeyboardInputAllowed;";

  bool get webkitHidden() native "return this.webkitHidden;";

  bool get webkitIsFullScreen() native "return this.webkitIsFullScreen;";

  String get webkitVisibilityState() native "return this.webkitVisibilityState;";

  String get xmlEncoding() native "return this.xmlEncoding;";

  bool get xmlStandalone() native "return this.xmlStandalone;";

  void set xmlStandalone(bool value) native "this.xmlStandalone = value;";

  String get xmlVersion() native "return this.xmlVersion;";

  void set xmlVersion(String value) native "this.xmlVersion = value;";

  NodeJS adoptNode(NodeJS source) native;

  RangeJS caretRangeFromPoint(int x, int y) native;

  AttrJS createAttribute(String name) native;

  AttrJS createAttributeNS(String namespaceURI, String qualifiedName) native;

  CDATASectionJS createCDATASection(String data) native;

  CommentJS createComment(String data) native;

  DocumentFragmentJS createDocumentFragment() native;

  ElementJS createElement(String tagName) native;

  ElementJS createElementNS(String namespaceURI, String qualifiedName) native;

  EntityReferenceJS createEntityReference(String name) native;

  EventJS createEvent(String eventType) native;

  XPathExpressionJS createExpression(String expression, XPathNSResolverJS resolver) native;

  XPathNSResolverJS createNSResolver(NodeJS nodeResolver) native;

  NodeIteratorJS createNodeIterator(NodeJS root, int whatToShow, NodeFilterJS filter, bool expandEntityReferences) native;

  ProcessingInstructionJS createProcessingInstruction(String target, String data) native;

  RangeJS createRange() native;

  TextJS createTextNode(String data) native;

  TouchJS createTouch(DOMWindowJS window, EventTargetJS target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native;

  TouchListJS createTouchList() native;

  TreeWalkerJS createTreeWalker(NodeJS root, int whatToShow, NodeFilterJS filter, bool expandEntityReferences) native;

  ElementJS elementFromPoint(int x, int y) native;

  XPathResultJS evaluate(String expression, NodeJS contextNode, XPathNSResolverJS resolver, int type, XPathResultJS inResult) native;

  bool execCommand(String command, bool userInterface, String value) native;

  Object getCSSCanvasContext(String contextId, String name, int width, int height) native;

  ElementJS getElementById(String elementId) native;

  NodeListJS getElementsByClassName(String tagname) native;

  NodeListJS getElementsByName(String elementName) native;

  NodeListJS getElementsByTagName(String tagname) native;

  NodeListJS getElementsByTagNameNS(String namespaceURI, String localName) native;

  CSSStyleDeclarationJS getOverrideStyle(ElementJS element, String pseudoElement) native;

  DOMSelectionJS getSelection() native;

  NodeJS importNode(NodeJS importedNode, [bool deep = null]) native;

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  ElementJS querySelector(String selectors) native;

  NodeListJS querySelectorAll(String selectors) native;

  void webkitCancelFullScreen() native;

  WebKitNamedFlowJS webkitGetFlowByName(String name) native;
}

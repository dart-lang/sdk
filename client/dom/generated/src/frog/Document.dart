
class DocumentJs extends NodeJs implements Document native "*Document" {

  String get URL() native "return this.URL;";

  HTMLCollectionJs get anchors() native "return this.anchors;";

  HTMLCollectionJs get applets() native "return this.applets;";

  HTMLElementJs get body() native "return this.body;";

  void set body(HTMLElementJs value) native "this.body = value;";

  String get characterSet() native "return this.characterSet;";

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  String get compatMode() native "return this.compatMode;";

  String get cookie() native "return this.cookie;";

  void set cookie(String value) native "this.cookie = value;";

  String get defaultCharset() native "return this.defaultCharset;";

  DOMWindowJs get defaultView() native "return this.defaultView;";

  DocumentTypeJs get doctype() native "return this.doctype;";

  ElementJs get documentElement() native "return this.documentElement;";

  String get documentURI() native "return this.documentURI;";

  void set documentURI(String value) native "this.documentURI = value;";

  String get domain() native "return this.domain;";

  void set domain(String value) native "this.domain = value;";

  HTMLCollectionJs get forms() native "return this.forms;";

  HTMLHeadElementJs get head() native "return this.head;";

  HTMLCollectionJs get images() native "return this.images;";

  DOMImplementationJs get implementation() native "return this.implementation;";

  String get inputEncoding() native "return this.inputEncoding;";

  String get lastModified() native "return this.lastModified;";

  HTMLCollectionJs get links() native "return this.links;";

  LocationJs get location() native "return this.location;";

  void set location(LocationJs value) native "this.location = value;";

  String get preferredStylesheetSet() native "return this.preferredStylesheetSet;";

  String get readyState() native "return this.readyState;";

  String get referrer() native "return this.referrer;";

  String get selectedStylesheetSet() native "return this.selectedStylesheetSet;";

  void set selectedStylesheetSet(String value) native "this.selectedStylesheetSet = value;";

  StyleSheetListJs get styleSheets() native "return this.styleSheets;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  ElementJs get webkitCurrentFullScreenElement() native "return this.webkitCurrentFullScreenElement;";

  bool get webkitFullScreenKeyboardInputAllowed() native "return this.webkitFullScreenKeyboardInputAllowed;";

  bool get webkitHidden() native "return this.webkitHidden;";

  bool get webkitIsFullScreen() native "return this.webkitIsFullScreen;";

  String get webkitVisibilityState() native "return this.webkitVisibilityState;";

  String get xmlEncoding() native "return this.xmlEncoding;";

  bool get xmlStandalone() native "return this.xmlStandalone;";

  void set xmlStandalone(bool value) native "this.xmlStandalone = value;";

  String get xmlVersion() native "return this.xmlVersion;";

  void set xmlVersion(String value) native "this.xmlVersion = value;";

  NodeJs adoptNode(NodeJs source) native;

  RangeJs caretRangeFromPoint(int x, int y) native;

  AttrJs createAttribute(String name) native;

  AttrJs createAttributeNS(String namespaceURI, String qualifiedName) native;

  CDATASectionJs createCDATASection(String data) native;

  CommentJs createComment(String data) native;

  DocumentFragmentJs createDocumentFragment() native;

  ElementJs createElement(String tagName) native;

  ElementJs createElementNS(String namespaceURI, String qualifiedName) native;

  EntityReferenceJs createEntityReference(String name) native;

  EventJs createEvent(String eventType) native;

  XPathExpressionJs createExpression(String expression, XPathNSResolverJs resolver) native;

  XPathNSResolverJs createNSResolver(NodeJs nodeResolver) native;

  NodeIteratorJs createNodeIterator(NodeJs root, int whatToShow, NodeFilterJs filter, bool expandEntityReferences) native;

  ProcessingInstructionJs createProcessingInstruction(String target, String data) native;

  RangeJs createRange() native;

  TextJs createTextNode(String data) native;

  TouchJs createTouch(DOMWindowJs window, EventTargetJs target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native;

  TouchListJs createTouchList() native;

  TreeWalkerJs createTreeWalker(NodeJs root, int whatToShow, NodeFilterJs filter, bool expandEntityReferences) native;

  ElementJs elementFromPoint(int x, int y) native;

  XPathResultJs evaluate(String expression, NodeJs contextNode, XPathNSResolverJs resolver, int type, XPathResultJs inResult) native;

  bool execCommand(String command, bool userInterface, String value) native;

  Object getCSSCanvasContext(String contextId, String name, int width, int height) native;

  ElementJs getElementById(String elementId) native;

  NodeListJs getElementsByClassName(String tagname) native;

  NodeListJs getElementsByName(String elementName) native;

  NodeListJs getElementsByTagName(String tagname) native;

  NodeListJs getElementsByTagNameNS(String namespaceURI, String localName) native;

  CSSStyleDeclarationJs getOverrideStyle(ElementJs element, String pseudoElement) native;

  DOMSelectionJs getSelection() native;

  NodeJs importNode(NodeJs importedNode, [bool deep = null]) native;

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  ElementJs querySelector(String selectors) native;

  NodeListJs querySelectorAll(String selectors) native;

  void webkitCancelFullScreen() native;

  WebKitNamedFlowJs webkitGetFlowByName(String name) native;
}

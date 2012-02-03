
class _DocumentJs extends _NodeJs implements Document native "*Document" {

  String get URL() native "return this.URL;";

  _HTMLCollectionJs get anchors() native "return this.anchors;";

  _HTMLCollectionJs get applets() native "return this.applets;";

  _HTMLElementJs get body() native "return this.body;";

  void set body(_HTMLElementJs value) native "this.body = value;";

  String get characterSet() native "return this.characterSet;";

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  String get compatMode() native "return this.compatMode;";

  String get cookie() native "return this.cookie;";

  void set cookie(String value) native "this.cookie = value;";

  String get defaultCharset() native "return this.defaultCharset;";

  _DOMWindowJs get defaultView() native "return this.defaultView;";

  _DocumentTypeJs get doctype() native "return this.doctype;";

  _ElementJs get documentElement() native "return this.documentElement;";

  String get documentURI() native "return this.documentURI;";

  void set documentURI(String value) native "this.documentURI = value;";

  String get domain() native "return this.domain;";

  void set domain(String value) native "this.domain = value;";

  _HTMLCollectionJs get forms() native "return this.forms;";

  _HTMLHeadElementJs get head() native "return this.head;";

  _HTMLCollectionJs get images() native "return this.images;";

  _DOMImplementationJs get implementation() native "return this.implementation;";

  String get inputEncoding() native "return this.inputEncoding;";

  String get lastModified() native "return this.lastModified;";

  _HTMLCollectionJs get links() native "return this.links;";

  _LocationJs get location() native "return this.location;";

  void set location(_LocationJs value) native "this.location = value;";

  String get preferredStylesheetSet() native "return this.preferredStylesheetSet;";

  String get readyState() native "return this.readyState;";

  String get referrer() native "return this.referrer;";

  String get selectedStylesheetSet() native "return this.selectedStylesheetSet;";

  void set selectedStylesheetSet(String value) native "this.selectedStylesheetSet = value;";

  _StyleSheetListJs get styleSheets() native "return this.styleSheets;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  _ElementJs get webkitCurrentFullScreenElement() native "return this.webkitCurrentFullScreenElement;";

  bool get webkitFullScreenKeyboardInputAllowed() native "return this.webkitFullScreenKeyboardInputAllowed;";

  bool get webkitHidden() native "return this.webkitHidden;";

  bool get webkitIsFullScreen() native "return this.webkitIsFullScreen;";

  String get webkitVisibilityState() native "return this.webkitVisibilityState;";

  String get xmlEncoding() native "return this.xmlEncoding;";

  bool get xmlStandalone() native "return this.xmlStandalone;";

  void set xmlStandalone(bool value) native "this.xmlStandalone = value;";

  String get xmlVersion() native "return this.xmlVersion;";

  void set xmlVersion(String value) native "this.xmlVersion = value;";

  _NodeJs adoptNode(_NodeJs source) native;

  _RangeJs caretRangeFromPoint(int x, int y) native;

  _AttrJs createAttribute(String name) native;

  _AttrJs createAttributeNS(String namespaceURI, String qualifiedName) native;

  _CDATASectionJs createCDATASection(String data) native;

  _CommentJs createComment(String data) native;

  _DocumentFragmentJs createDocumentFragment() native;

  _ElementJs createElement(String tagName) native;

  _ElementJs createElementNS(String namespaceURI, String qualifiedName) native;

  _EntityReferenceJs createEntityReference(String name) native;

  _EventJs createEvent(String eventType) native;

  _XPathExpressionJs createExpression(String expression, _XPathNSResolverJs resolver) native;

  _XPathNSResolverJs createNSResolver(_NodeJs nodeResolver) native;

  _NodeIteratorJs createNodeIterator(_NodeJs root, int whatToShow, _NodeFilterJs filter, bool expandEntityReferences) native;

  _ProcessingInstructionJs createProcessingInstruction(String target, String data) native;

  _RangeJs createRange() native;

  _TextJs createTextNode(String data) native;

  _TouchJs createTouch(_DOMWindowJs window, _EventTargetJs target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native;

  _TouchListJs createTouchList() native;

  _TreeWalkerJs createTreeWalker(_NodeJs root, int whatToShow, _NodeFilterJs filter, bool expandEntityReferences) native;

  _ElementJs elementFromPoint(int x, int y) native;

  _XPathResultJs evaluate(String expression, _NodeJs contextNode, _XPathNSResolverJs resolver, int type, _XPathResultJs inResult) native;

  bool execCommand(String command, bool userInterface, String value) native;

  Object getCSSCanvasContext(String contextId, String name, int width, int height) native;

  _ElementJs getElementById(String elementId) native;

  _NodeListJs getElementsByClassName(String tagname) native;

  _NodeListJs getElementsByName(String elementName) native;

  _NodeListJs getElementsByTagName(String tagname) native;

  _NodeListJs getElementsByTagNameNS(String namespaceURI, String localName) native;

  _CSSStyleDeclarationJs getOverrideStyle(_ElementJs element, String pseudoElement) native;

  _DOMSelectionJs getSelection() native;

  _NodeJs importNode(_NodeJs importedNode, [bool deep = null]) native;

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  _ElementJs querySelector(String selectors) native;

  _NodeListJs querySelectorAll(String selectors) native;

  void webkitCancelFullScreen() native;

  _WebKitNamedFlowJs webkitGetFlowByName(String name) native;
}

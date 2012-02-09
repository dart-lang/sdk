
class _DocumentJs extends _NodeJs implements Document native "*Document" {

  final String URL;

  final _HTMLCollectionJs anchors;

  final _HTMLCollectionJs applets;

  _HTMLElementJs body;

  final String characterSet;

  String charset;

  final String compatMode;

  String cookie;

  final String defaultCharset;

  final _DOMWindowJs defaultView;

  final _DocumentTypeJs doctype;

  final _ElementJs documentElement;

  String documentURI;

  String domain;

  final _HTMLCollectionJs forms;

  final _HTMLHeadElementJs head;

  final _HTMLCollectionJs images;

  final _DOMImplementationJs implementation;

  final String inputEncoding;

  final String lastModified;

  final _HTMLCollectionJs links;

  _LocationJs location;

  final String preferredStylesheetSet;

  final String readyState;

  final String referrer;

  String selectedStylesheetSet;

  final _StyleSheetListJs styleSheets;

  String title;

  final _ElementJs webkitCurrentFullScreenElement;

  final bool webkitFullScreenKeyboardInputAllowed;

  final bool webkitHidden;

  final bool webkitIsFullScreen;

  final String webkitVisibilityState;

  final String xmlEncoding;

  bool xmlStandalone;

  String xmlVersion;

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

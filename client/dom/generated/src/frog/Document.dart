
class Document extends Node native "*Document" {

  String URL;

  HTMLCollection anchors;

  HTMLCollection applets;

  HTMLElement body;

  String characterSet;

  String charset;

  String compatMode;

  String cookie;

  String defaultCharset;

  DOMWindow defaultView;

  DocumentType doctype;

  Element documentElement;

  String documentURI;

  String domain;

  HTMLCollection forms;

  HTMLHeadElement head;

  HTMLCollection images;

  DOMImplementation implementation;

  String inputEncoding;

  String lastModified;

  HTMLCollection links;

  Location location;

  String preferredStylesheetSet;

  String readyState;

  String referrer;

  String selectedStylesheetSet;

  StyleSheetList styleSheets;

  String title;

  bool webkitHidden;

  String webkitVisibilityState;

  String xmlEncoding;

  bool xmlStandalone;

  String xmlVersion;

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

  Node importNode(Node importedNode, bool deep) native;

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;
}

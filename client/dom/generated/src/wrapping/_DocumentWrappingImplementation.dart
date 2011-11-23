// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DocumentWrappingImplementation extends _NodeWrappingImplementation implements Document {
  _DocumentWrappingImplementation() : super() {}

  static create__DocumentWrappingImplementation() native {
    return new _DocumentWrappingImplementation();
  }

  String get URL() { return _get_URL(this); }
  static String _get_URL(var _this) native;

  HTMLCollection get anchors() { return _get_anchors(this); }
  static HTMLCollection _get_anchors(var _this) native;

  HTMLCollection get applets() { return _get_applets(this); }
  static HTMLCollection _get_applets(var _this) native;

  HTMLElement get body() { return _get_body(this); }
  static HTMLElement _get_body(var _this) native;

  void set body(HTMLElement value) { _set_body(this, value); }
  static void _set_body(var _this, HTMLElement value) native;

  String get characterSet() { return _get_characterSet(this); }
  static String _get_characterSet(var _this) native;

  String get charset() { return _get_charset(this); }
  static String _get_charset(var _this) native;

  void set charset(String value) { _set_charset(this, value); }
  static void _set_charset(var _this, String value) native;

  String get compatMode() { return _get_compatMode(this); }
  static String _get_compatMode(var _this) native;

  String get cookie() { return _get_cookie(this); }
  static String _get_cookie(var _this) native;

  void set cookie(String value) { _set_cookie(this, value); }
  static void _set_cookie(var _this, String value) native;

  String get defaultCharset() { return _get_defaultCharset(this); }
  static String _get_defaultCharset(var _this) native;

  DOMWindow get defaultView() { return _get_defaultView(this); }
  static DOMWindow _get_defaultView(var _this) native;

  DocumentType get doctype() { return _get_doctype(this); }
  static DocumentType _get_doctype(var _this) native;

  Element get documentElement() { return _get_documentElement(this); }
  static Element _get_documentElement(var _this) native;

  String get documentURI() { return _get_documentURI(this); }
  static String _get_documentURI(var _this) native;

  void set documentURI(String value) { _set_documentURI(this, value); }
  static void _set_documentURI(var _this, String value) native;

  String get domain() { return _get_domain(this); }
  static String _get_domain(var _this) native;

  void set domain(String value) { _set_domain(this, value); }
  static void _set_domain(var _this, String value) native;

  HTMLCollection get forms() { return _get_forms(this); }
  static HTMLCollection _get_forms(var _this) native;

  HTMLHeadElement get head() { return _get_head(this); }
  static HTMLHeadElement _get_head(var _this) native;

  HTMLCollection get images() { return _get_images(this); }
  static HTMLCollection _get_images(var _this) native;

  DOMImplementation get implementation() { return _get_implementation(this); }
  static DOMImplementation _get_implementation(var _this) native;

  String get inputEncoding() { return _get_inputEncoding(this); }
  static String _get_inputEncoding(var _this) native;

  String get lastModified() { return _get_lastModified(this); }
  static String _get_lastModified(var _this) native;

  HTMLCollection get links() { return _get_links(this); }
  static HTMLCollection _get_links(var _this) native;

  Location get location() { return _get_location(this); }
  static Location _get_location(var _this) native;

  void set location(Location value) { _set_location(this, value); }
  static void _set_location(var _this, Location value) native;

  String get preferredStylesheetSet() { return _get_preferredStylesheetSet(this); }
  static String _get_preferredStylesheetSet(var _this) native;

  String get readyState() { return _get_readyState(this); }
  static String _get_readyState(var _this) native;

  String get referrer() { return _get_referrer(this); }
  static String _get_referrer(var _this) native;

  String get selectedStylesheetSet() { return _get_selectedStylesheetSet(this); }
  static String _get_selectedStylesheetSet(var _this) native;

  void set selectedStylesheetSet(String value) { _set_selectedStylesheetSet(this, value); }
  static void _set_selectedStylesheetSet(var _this, String value) native;

  StyleSheetList get styleSheets() { return _get_styleSheets(this); }
  static StyleSheetList _get_styleSheets(var _this) native;

  String get title() { return _get_title(this); }
  static String _get_title(var _this) native;

  void set title(String value) { _set_title(this, value); }
  static void _set_title(var _this, String value) native;

  bool get webkitHidden() { return _get_webkitHidden(this); }
  static bool _get_webkitHidden(var _this) native;

  String get webkitVisibilityState() { return _get_webkitVisibilityState(this); }
  static String _get_webkitVisibilityState(var _this) native;

  String get xmlEncoding() { return _get_xmlEncoding(this); }
  static String _get_xmlEncoding(var _this) native;

  bool get xmlStandalone() { return _get_xmlStandalone(this); }
  static bool _get_xmlStandalone(var _this) native;

  void set xmlStandalone(bool value) { _set_xmlStandalone(this, value); }
  static void _set_xmlStandalone(var _this, bool value) native;

  String get xmlVersion() { return _get_xmlVersion(this); }
  static String _get_xmlVersion(var _this) native;

  void set xmlVersion(String value) { _set_xmlVersion(this, value); }
  static void _set_xmlVersion(var _this, String value) native;

  Node adoptNode(Node source) {
    return _adoptNode(this, source);
  }
  static Node _adoptNode(receiver, source) native;

  Range caretRangeFromPoint(int x, int y) {
    return _caretRangeFromPoint(this, x, y);
  }
  static Range _caretRangeFromPoint(receiver, x, y) native;

  Attr createAttribute(String name) {
    return _createAttribute(this, name);
  }
  static Attr _createAttribute(receiver, name) native;

  Attr createAttributeNS(String namespaceURI, String qualifiedName) {
    return _createAttributeNS(this, namespaceURI, qualifiedName);
  }
  static Attr _createAttributeNS(receiver, namespaceURI, qualifiedName) native;

  CDATASection createCDATASection(String data) {
    return _createCDATASection(this, data);
  }
  static CDATASection _createCDATASection(receiver, data) native;

  Comment createComment(String data) {
    return _createComment(this, data);
  }
  static Comment _createComment(receiver, data) native;

  DocumentFragment createDocumentFragment() {
    return _createDocumentFragment(this);
  }
  static DocumentFragment _createDocumentFragment(receiver) native;

  Element createElement(String tagName) {
    return _createElement(this, tagName);
  }
  static Element _createElement(receiver, tagName) native;

  Element createElementNS(String namespaceURI, String qualifiedName) {
    return _createElementNS(this, namespaceURI, qualifiedName);
  }
  static Element _createElementNS(receiver, namespaceURI, qualifiedName) native;

  EntityReference createEntityReference(String name) {
    return _createEntityReference(this, name);
  }
  static EntityReference _createEntityReference(receiver, name) native;

  Event createEvent(String eventType) {
    return _createEvent(this, eventType);
  }
  static Event _createEvent(receiver, eventType) native;

  XPathExpression createExpression(String expression, XPathNSResolver resolver) {
    return _createExpression(this, expression, resolver);
  }
  static XPathExpression _createExpression(receiver, expression, resolver) native;

  XPathNSResolver createNSResolver(Node nodeResolver) {
    return _createNSResolver(this, nodeResolver);
  }
  static XPathNSResolver _createNSResolver(receiver, nodeResolver) native;

  NodeIterator createNodeIterator(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences) {
    return _createNodeIterator(this, root, whatToShow, filter, expandEntityReferences);
  }
  static NodeIterator _createNodeIterator(receiver, root, whatToShow, filter, expandEntityReferences) native;

  ProcessingInstruction createProcessingInstruction(String target, String data) {
    return _createProcessingInstruction(this, target, data);
  }
  static ProcessingInstruction _createProcessingInstruction(receiver, target, data) native;

  Range createRange() {
    return _createRange(this);
  }
  static Range _createRange(receiver) native;

  Text createTextNode(String data) {
    return _createTextNode(this, data);
  }
  static Text _createTextNode(receiver, data) native;

  TreeWalker createTreeWalker(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences) {
    return _createTreeWalker(this, root, whatToShow, filter, expandEntityReferences);
  }
  static TreeWalker _createTreeWalker(receiver, root, whatToShow, filter, expandEntityReferences) native;

  Element elementFromPoint(int x, int y) {
    return _elementFromPoint(this, x, y);
  }
  static Element _elementFromPoint(receiver, x, y) native;

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) {
    return _evaluate(this, expression, contextNode, resolver, type, inResult);
  }
  static XPathResult _evaluate(receiver, expression, contextNode, resolver, type, inResult) native;

  bool execCommand(String command, bool userInterface, String value) {
    return _execCommand(this, command, userInterface, value);
  }
  static bool _execCommand(receiver, command, userInterface, value) native;

  Object getCSSCanvasContext(String contextId, String name, int width, int height) {
    return _getCSSCanvasContext(this, contextId, name, width, height);
  }
  static Object _getCSSCanvasContext(receiver, contextId, name, width, height) native;

  Element getElementById(String elementId) {
    return _getElementById(this, elementId);
  }
  static Element _getElementById(receiver, elementId) native;

  NodeList getElementsByClassName(String tagname) {
    return _getElementsByClassName(this, tagname);
  }
  static NodeList _getElementsByClassName(receiver, tagname) native;

  NodeList getElementsByName(String elementName) {
    return _getElementsByName(this, elementName);
  }
  static NodeList _getElementsByName(receiver, elementName) native;

  NodeList getElementsByTagName(String tagname) {
    return _getElementsByTagName(this, tagname);
  }
  static NodeList _getElementsByTagName(receiver, tagname) native;

  NodeList getElementsByTagNameNS(String namespaceURI, String localName) {
    return _getElementsByTagNameNS(this, namespaceURI, localName);
  }
  static NodeList _getElementsByTagNameNS(receiver, namespaceURI, localName) native;

  CSSStyleDeclaration getOverrideStyle(Element element, String pseudoElement) {
    return _getOverrideStyle(this, element, pseudoElement);
  }
  static CSSStyleDeclaration _getOverrideStyle(receiver, element, pseudoElement) native;

  DOMSelection getSelection() {
    return _getSelection(this);
  }
  static DOMSelection _getSelection(receiver) native;

  Node importNode(Node importedNode, bool deep) {
    return _importNode(this, importedNode, deep);
  }
  static Node _importNode(receiver, importedNode, deep) native;

  bool queryCommandEnabled(String command) {
    return _queryCommandEnabled(this, command);
  }
  static bool _queryCommandEnabled(receiver, command) native;

  bool queryCommandIndeterm(String command) {
    return _queryCommandIndeterm(this, command);
  }
  static bool _queryCommandIndeterm(receiver, command) native;

  bool queryCommandState(String command) {
    return _queryCommandState(this, command);
  }
  static bool _queryCommandState(receiver, command) native;

  bool queryCommandSupported(String command) {
    return _queryCommandSupported(this, command);
  }
  static bool _queryCommandSupported(receiver, command) native;

  String queryCommandValue(String command) {
    return _queryCommandValue(this, command);
  }
  static String _queryCommandValue(receiver, command) native;

  Element querySelector(String selectors) {
    return _querySelector(this, selectors);
  }
  static Element _querySelector(receiver, selectors) native;

  NodeList querySelectorAll(String selectors) {
    return _querySelectorAll(this, selectors);
  }
  static NodeList _querySelectorAll(receiver, selectors) native;

  String get typeName() { return "Document"; }
}

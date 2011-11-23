// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Document extends Node, NodeSelector {

  String get URL();

  HTMLCollection get anchors();

  HTMLCollection get applets();

  HTMLElement get body();

  void set body(HTMLElement value);

  String get characterSet();

  String get charset();

  void set charset(String value);

  String get compatMode();

  String get cookie();

  void set cookie(String value);

  String get defaultCharset();

  DOMWindow get defaultView();

  DocumentType get doctype();

  Element get documentElement();

  String get documentURI();

  void set documentURI(String value);

  String get domain();

  void set domain(String value);

  HTMLCollection get forms();

  HTMLHeadElement get head();

  HTMLCollection get images();

  DOMImplementation get implementation();

  String get inputEncoding();

  String get lastModified();

  HTMLCollection get links();

  Location get location();

  void set location(Location value);

  String get preferredStylesheetSet();

  String get readyState();

  String get referrer();

  String get selectedStylesheetSet();

  void set selectedStylesheetSet(String value);

  StyleSheetList get styleSheets();

  String get title();

  void set title(String value);

  bool get webkitHidden();

  String get webkitVisibilityState();

  String get xmlEncoding();

  bool get xmlStandalone();

  void set xmlStandalone(bool value);

  String get xmlVersion();

  void set xmlVersion(String value);

  Node adoptNode(Node source);

  Range caretRangeFromPoint(int x, int y);

  Attr createAttribute(String name);

  Attr createAttributeNS(String namespaceURI, String qualifiedName);

  CDATASection createCDATASection(String data);

  Comment createComment(String data);

  DocumentFragment createDocumentFragment();

  Element createElement(String tagName);

  Element createElementNS(String namespaceURI, String qualifiedName);

  EntityReference createEntityReference(String name);

  Event createEvent(String eventType);

  XPathExpression createExpression(String expression, XPathNSResolver resolver);

  XPathNSResolver createNSResolver(Node nodeResolver);

  NodeIterator createNodeIterator(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences);

  ProcessingInstruction createProcessingInstruction(String target, String data);

  Range createRange();

  Text createTextNode(String data);

  TreeWalker createTreeWalker(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences);

  Element elementFromPoint(int x, int y);

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult);

  bool execCommand(String command, bool userInterface, String value);

  Object getCSSCanvasContext(String contextId, String name, int width, int height);

  Element getElementById(String elementId);

  NodeList getElementsByClassName(String tagname);

  NodeList getElementsByName(String elementName);

  NodeList getElementsByTagName(String tagname);

  NodeList getElementsByTagNameNS(String namespaceURI, String localName);

  CSSStyleDeclaration getOverrideStyle(Element element, String pseudoElement);

  DOMSelection getSelection();

  Node importNode(Node importedNode, bool deep);

  bool queryCommandEnabled(String command);

  bool queryCommandIndeterm(String command);

  bool queryCommandState(String command);

  bool queryCommandSupported(String command);

  String queryCommandValue(String command);

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);
}

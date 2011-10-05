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

  HTMLCollection get forms();

  HTMLHeadElement get head();

  HTMLCollection get images();

  DOMImplementation get implementation();

  String get inputEncoding();

  String get lastModified();

  HTMLCollection get links();

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get onbeforecopy();

  void set onbeforecopy(EventListener value);

  EventListener get onbeforecut();

  void set onbeforecut(EventListener value);

  EventListener get onbeforepaste();

  void set onbeforepaste(EventListener value);

  EventListener get onblur();

  void set onblur(EventListener value);

  EventListener get onchange();

  void set onchange(EventListener value);

  EventListener get onclick();

  void set onclick(EventListener value);

  EventListener get oncontextmenu();

  void set oncontextmenu(EventListener value);

  EventListener get oncopy();

  void set oncopy(EventListener value);

  EventListener get oncut();

  void set oncut(EventListener value);

  EventListener get ondblclick();

  void set ondblclick(EventListener value);

  EventListener get ondrag();

  void set ondrag(EventListener value);

  EventListener get ondragend();

  void set ondragend(EventListener value);

  EventListener get ondragenter();

  void set ondragenter(EventListener value);

  EventListener get ondragleave();

  void set ondragleave(EventListener value);

  EventListener get ondragover();

  void set ondragover(EventListener value);

  EventListener get ondragstart();

  void set ondragstart(EventListener value);

  EventListener get ondrop();

  void set ondrop(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onfocus();

  void set onfocus(EventListener value);

  EventListener get oninput();

  void set oninput(EventListener value);

  EventListener get oninvalid();

  void set oninvalid(EventListener value);

  EventListener get onkeydown();

  void set onkeydown(EventListener value);

  EventListener get onkeypress();

  void set onkeypress(EventListener value);

  EventListener get onkeyup();

  void set onkeyup(EventListener value);

  EventListener get onload();

  void set onload(EventListener value);

  EventListener get onmousedown();

  void set onmousedown(EventListener value);

  EventListener get onmousemove();

  void set onmousemove(EventListener value);

  EventListener get onmouseout();

  void set onmouseout(EventListener value);

  EventListener get onmouseover();

  void set onmouseover(EventListener value);

  EventListener get onmouseup();

  void set onmouseup(EventListener value);

  EventListener get onmousewheel();

  void set onmousewheel(EventListener value);

  EventListener get onpaste();

  void set onpaste(EventListener value);

  EventListener get onreadystatechange();

  void set onreadystatechange(EventListener value);

  EventListener get onreset();

  void set onreset(EventListener value);

  EventListener get onscroll();

  void set onscroll(EventListener value);

  EventListener get onsearch();

  void set onsearch(EventListener value);

  EventListener get onselect();

  void set onselect(EventListener value);

  EventListener get onselectionchange();

  void set onselectionchange(EventListener value);

  EventListener get onselectstart();

  void set onselectstart(EventListener value);

  EventListener get onsubmit();

  void set onsubmit(EventListener value);

  EventListener get ontouchcancel();

  void set ontouchcancel(EventListener value);

  EventListener get ontouchend();

  void set ontouchend(EventListener value);

  EventListener get ontouchmove();

  void set ontouchmove(EventListener value);

  EventListener get ontouchstart();

  void set ontouchstart(EventListener value);

  EventListener get onwebkitfullscreenchange();

  void set onwebkitfullscreenchange(EventListener value);

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

  Node adoptNode(Node source = null);

  Range caretRangeFromPoint(int x = null, int y = null);

  Attr createAttribute(String name = null);

  Attr createAttributeNS(String namespaceURI = null, String qualifiedName = null);

  CDATASection createCDATASection(String data = null);

  CSSStyleDeclaration createCSSStyleDeclaration();

  Comment createComment(String data = null);

  DocumentFragment createDocumentFragment();

  Element createElement(String tagName = null);

  Element createElementNS(String namespaceURI = null, String qualifiedName = null);

  EntityReference createEntityReference(String name = null);

  Event createEvent(String eventType = null);

  NodeIterator createNodeIterator(Node root = null, int whatToShow = null, NodeFilter filter = null, bool expandEntityReferences = null);

  ProcessingInstruction createProcessingInstruction(String target = null, String data = null);

  Range createRange();

  Text createTextNode(String data = null);

  TreeWalker createTreeWalker(Node root = null, int whatToShow = null, NodeFilter filter = null, bool expandEntityReferences = null);

  Element elementFromPoint(int x = null, int y = null);

  bool execCommand(String command = null, bool userInterface = null, String value = null);

  Object getCSSCanvasContext(String contextId, String name, int width, int height);

  Element getElementById(String elementId = null);

  NodeList getElementsByClassName(String tagname = null);

  NodeList getElementsByName(String elementName = null);

  NodeList getElementsByTagName(String tagname = null);

  NodeList getElementsByTagNameNS(String namespaceURI = null, String localName = null);

  CSSStyleDeclaration getOverrideStyle(Element element = null, String pseudoElement = null);

  Node importNode(Node importedNode = null, bool deep = null);

  bool queryCommandEnabled(String command = null);

  bool queryCommandIndeterm(String command = null);

  bool queryCommandState(String command = null);

  bool queryCommandSupported(String command = null);

  String queryCommandValue(String command = null);

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);
}

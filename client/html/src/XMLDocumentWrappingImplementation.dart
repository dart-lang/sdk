// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class XMLDocumentWrappingImplementation extends DocumentWrappingImplementation
    implements XMLDocument {
  // This really just wants to extend both DocumentWrappingImplementation and
  // XMLElementWrappingImplementation, but since that's not possible we delegate
  // to the latter.
  XMLElement documentEl;

  XMLDocumentWrappingImplementation._wrap(documentPtr, ptr) :
      super._wrap(documentPtr, ptr) {
    // We want to wrap the pointer in an XMLElement to use its implementation of
    // various Element methods, but DOMWrapperBase complains if
    // dartObjectLocalStorage is already set.
    ptr.dartObjectLocalStorage = null;
    this.documentEl = new XMLElementWrappingImplementation._wrap(ptr);
    ptr.dartObjectLocalStorage = this;
  }

  factory XMLDocumentWrappingImplementation.xml(String xml) {
    final parser = new dom.DOMParser();
    final xmlDoc = LevelDom.wrapDocument(
        parser.parseFromString(xml, 'text/xml'));
    // When XML parsing fails, the browser creates a document containing a
    // PARSERERROR element. We want to throw an exception when parsing fails,
    // but we don't want false positives if the user intends to create a
    // PARSERERROR element for some reason, so we check for that in the input.
    //
    // TODO(nweiz): This is pretty hacky, it would be nice to this some other
    // way if we can find one.
    if (!xml.toLowerCase().contains('<parsererror') &&
        xmlDoc.query('parsererror') != null) {
      throw new IllegalArgumentException('Error parsing XML: "$xml"');
    }
    return xmlDoc;
  }

  Node get parent() => null;

  Node _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case "beforebegin":
        return null;
      case "afterend":
        return null;
      case "afterbegin":
        this.insertBefore(node, nodes.first);
        return node;
      case "beforeend":
        this.nodes.add(node);
        return node;
      default:
        throw new IllegalArgumentException("Invalid position ${where}");
    }
  }

  XMLElement insertAdjacentElement([String where = null,
      XMLElement element = null]) => this._insertAdjacentNode(where, element);

  void insertAdjacentText([String where = null, String text = null]) {
    this._insertAdjacentNode(where, new Text(text));
  }

  void insertAdjacentHTML(
      [String position_OR_where = null, String text = null]) {
    this._insertAdjacentNode(
      position_OR_where, new DocumentFragment.xml(text));
  }

  Future<ElementRect> get rect() => documentEl.rect;

  Future<Range> caretRangeFromPoint([int x = null, int y = null]) =>
    new Future<Range>.immediate(null);

  Future<Element> elementFromPoint([int x = null, int y = null]) =>
    new Future<Element>.immediate(null);

  bool execCommand([String command = null, bool userInterface = null,
      String value = null]) => false;

  bool queryCommandEnabled([String command = null]) => false;
  bool queryCommandIndeterm([String command = null]) => false;
  bool queryCommandState([String command = null]) => false;
  bool queryCommandSupported([String command = null]) => false;
  void blur() {}
  void focus() {}
  void scrollByLines([int lines = null]) {}
  void scrollByPages([int pages = null]) {}
  void scrollIntoView([bool centerIfNeeded = null]) {}
  XMLElement get activeElement() => null;
  String get domain() => "";

  void set body(Element value) {
    throw new UnsupportedOperationException("XML documents don't have a body.");
  }

  String get cookie() {
    throw new UnsupportedOperationException(
        "XML documents don't support cookies.");
  }

  void set cookie(String value) {
    throw new UnsupportedOperationException(
        "XML documents don't support cookies.");
  }

  String get manifest() => "";

  void set manifest(String value) {
    throw new UnsupportedOperationException(
        "Manifest can't be set for XML documents.");
  }

  Set<String> get classes() => documentEl.classes;

  ElementList get elements() => documentEl.elements;

  void set elements(Collection<Element> value) { documentEl.elements = value; }

  String get outerHTML() => documentEl.outerHTML;

  String get innerHTML() => documentEl.innerHTML;

  void set innerHTML(String xml) { documentEl.innerHTML = xml; }

  String get contentEditable() => documentEl.contentEditable;

  void set contentEditable(String value) { documentEl.contentEditable = value; }

  bool get isContentEditable() => documentEl.isContentEditable;

  bool get draggable() => documentEl.draggable;

  void set draggable(bool value) { documentEl.draggable = value; }

  bool get spellcheck() => documentEl.spellcheck;

  void set spellcheck(bool value) { documentEl.spellcheck = value; }

  bool get hidden() => documentEl.hidden;

  void set hidden(bool value) { documentEl.hidden = value; }

  int get tabIndex() => documentEl.tabIndex;

  void set tabIndex(int value) { documentEl.tabIndex = value; }

  String get id() => documentEl.id;

  void set id(String value) { documentEl.id = value; }

  String get title() => documentEl.title;

  void set title(String value) { documentEl.title = value; }

  String get webkitdropzone() => documentEl.webkitdropzone;

  void set webkitdropzone(String value) { documentEl.webkitdropzone = value; }

  String get lang() => documentEl.lang;

  void set lang(String value) { documentEl.lang = value; }

  String get dir() => documentEl.dir;

  void set dir(String value) { documentEl.dir = value; }
}

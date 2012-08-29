// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FilteredElementList implements ElementList {
  final Node _node;
  final NodeList _childNodes;

  FilteredElementList(Node node): _childNodes = node.nodes, _node = node;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  //
  // TODO(nweiz): Do we really need to copy the list to make the types work out?
  List<Element> get _filtered() =>
    new List.from(_childNodes.filter((n) => n is Element));

  // Don't use _filtered.first so we can short-circuit once we find an element.
  Element get first() {
    for (var node in _childNodes) {
      if (node is Element) {
        return node;
      }
    }
    return null;
  }

  void forEach(void f(Element element)) {
    _filtered.forEach(f);
  }

  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  void set length(int newLength) {
    var len = this.length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw const IllegalArgumentException("Invalid list length");
    }

    removeRange(newLength - 1, len - newLength);
  }

  void add(Element value) {
    _childNodes.add(value);
  }

  void addAll(Collection<Element> collection) {
    collection.forEach(add);
  }

  void addLast(Element value) {
    add(value);
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    _filtered.getRange(start, length).forEach((el) => el.remove());
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  Element removeLast() {
    var last = this.last();
    if (last != null) {
      last.remove();
    }
    return last;
  }

  Collection map(f(Element element)) => _filtered.map(f);
  Collection<Element> filter(bool f(Element element)) => _filtered.filter(f);
  bool every(bool f(Element element)) => _filtered.every(f);
  bool some(bool f(Element element)) => _filtered.some(f);
  bool isEmpty() => _filtered.isEmpty();
  int get length() => _filtered.length;
  Element operator [](int index) => _filtered[index];
  Iterator<Element> iterator() => _filtered.iterator();
  List<Element> getRange(int start, int length) =>
    _filtered.getRange(start, length);
  int indexOf(Element element, [int start = 0]) =>
    _filtered.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return _filtered.lastIndexOf(element, start);
  }

  Element last() => _filtered.last();
}

class EmptyStyleDeclaration extends CSSStyleDeclarationWrappingImplementation {
  // This can't call super(), since that's a factory constructor
  EmptyStyleDeclaration()
    : super._wrap(dom.document.createElement('div').style);

  void set cssText(String value) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }

  String removeProperty(String propertyName) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }

  void setProperty(String propertyName, String value, [String priority]) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }
}

Future<CSSStyleDeclaration> _emptyStyleFuture() {
  return _createMeasurementFuture(() => new EmptyStyleDeclaration(),
                                  new Completer<CSSStyleDeclaration>());
}

class EmptyElementRect implements ElementRect {
  final ClientRect client = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect offset = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect scroll = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect bounding = const SimpleClientRect(0, 0, 0, 0);
  final List<ClientRect> clientRects = const <ClientRect>[];

  const EmptyElementRect();
}

class DocumentFragmentWrappingImplementation extends NodeWrappingImplementation implements DocumentFragment {
  ElementList _elements;

  DocumentFragmentWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  /** @domName Document.createDocumentFragment */
  factory DocumentFragmentWrappingImplementation() {
    return new DocumentFragmentWrappingImplementation._wrap(
	    dom.document.createDocumentFragment());
  }

  factory DocumentFragmentWrappingImplementation.html(String html) {
    var fragment = new DocumentFragment();
    fragment.innerHTML = html;
    return fragment;
  }

  factory DocumentFragmentWrappingImplementation.xml(String xml) {
    var fragment = new DocumentFragment();
    var e = new XMLElement.tag("xml");
    e.innerHTML = xml;

    // Copy list first since we don't want liveness during iteration.
    List nodes = new List.from(e.nodes);
    fragment.nodes.addAll(nodes);
    return fragment;
  }

  factory DocumentFragmentWrappingImplementation.svg(String svg) {
    var fragment = new DocumentFragment();
    var e = new SVGSVGElement();
    e.innerHTML = svg;

    // Copy list first since we don't want liveness during iteration.
    List nodes = new List.from(e.nodes);
    fragment.nodes.addAll(nodes);
    return fragment;
  }

  ElementList get elements() {
    if (_elements == null) {
      _elements = new FilteredElementList(this);
    }
    return _elements;
  }

  void set elements(Collection<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    final elements = this.elements;
    elements.clear();
    elements.addAll(copy);
  }

  String get innerHTML() {
    var e = new Element.tag("div");
    e.nodes.add(this.clone(true));
    return e.innerHTML;
  }

  String get outerHTML() => innerHTML;

  // TODO(nweiz): Do we want to support some variant of innerHTML for XML and/or
  // SVG strings?
  void set innerHTML(String value) {
    this.nodes.clear();

    var e = new Element.tag("div");
    e.innerHTML = value;

    // Copy list first since we don't want liveness during iteration.
    List nodes = new List.from(e.nodes);
    this.nodes.addAll(nodes);
  }

  Node _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case "beforebegin": return null;
      case "afterend": return null;
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

  Element insertAdjacentElement([String where = null, Element element = null])
    => this._insertAdjacentNode(where, element);

  void insertAdjacentText([String where = null, String text = null]) {
    this._insertAdjacentNode(where, new Text(text));
  }

  void insertAdjacentHTML(
      [String position_OR_where = null, String text = null]) {
    this._insertAdjacentNode(
      position_OR_where, new DocumentFragment.html(text));
  }

  ElementEvents get on() {
    if (_on === null) {
      _on = new ElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }

  Future<ElementRect> get rect() {
    return _createMeasurementFuture(() => const EmptyElementRect(),
                                    new Completer<ElementRect>());
  }

  Element query(String selectors) =>
    LevelDom.wrapElement(_ptr.querySelector(selectors));

  ElementList queryAll(String selectors) =>
    LevelDom.wrapElementList(_ptr.querySelectorAll(selectors));

  // If we can come up with a semi-reasonable default value for an Element
  // getter, we'll use it. In general, these return the same values as an
  // element that has no parent.
  String get contentEditable() => "false";
  bool get isContentEditable() => false;
  bool get draggable() => false;
  bool get hidden() => false;
  bool get spellcheck() => false;
  int get tabIndex() => -1;
  String get id() => "";
  String get title() => "";
  String get tagName() => "";
  String get webkitdropzone() => "";
  Element get firstElementChild() => elements.first();
  Element get lastElementChild() => elements.last();
  Element get nextElementSibling() => null;
  Element get previousElementSibling() => null;
  Element get offsetParent() => null;
  Element get parent() => null;
  Map<String, String> get attributes() => const {};
  CSSClassSet get classes() => null;
  Map<String, String> get dataAttributes() => const {};
  CSSStyleDeclaration get style() => new EmptyStyleDeclaration();
  Future<CSSStyleDeclaration> get computedStyle() =>
      _emptyStyleFuture();
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) =>
      _emptyStyleFuture();
  bool matchesSelector([String selectors]) => false;

  // Imperative Element methods are made into no-ops, as they are on parentless
  // elements.
  void blur() {}
  void focus() {}
  void scrollByLines([int lines]) {}
  void scrollByPages([int pages]) {}
  void scrollIntoView([bool centerIfNeeded]) {}

  // Setters throw errors rather than being no-ops because we aren't going to
  // retain the values that were set, and erroring out seems clearer.
  void set attributes(Map<String, String> value) {
    throw new UnsupportedOperationException(
      "Attributes can't be set for document fragments.");
  }

  void set classes(Collection<String> value) {
    throw new UnsupportedOperationException(
      "Classes can't be set for document fragments.");
  }

  void set dataAttributes(Map<String, String> value) {
    throw new UnsupportedOperationException(
      "Data attributes can't be set for document fragments.");
  }

  void set contentEditable(String value) {
    throw new UnsupportedOperationException(
      "Content editable can't be set for document fragments.");
  }

  String get dir() {
    throw new UnsupportedOperationException(
      "Document fragments don't support text direction.");
  }

  void set dir(String value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support text direction.");
  }

  void set draggable(bool value) {
    throw new UnsupportedOperationException(
      "Draggable can't be set for document fragments.");
  }

  void set hidden(bool value) {
    throw new UnsupportedOperationException(
      "Hidden can't be set for document fragments.");
  }

  void set id(String value) {
    throw new UnsupportedOperationException(
      "ID can't be set for document fragments.");
  }

  String get lang() {
    throw new UnsupportedOperationException(
      "Document fragments don't support language.");
  }

  void set lang(String value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support language.");
  }

  void set scrollLeft(int value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support scrolling.");
  }

  void set scrollTop(int value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support scrolling.");
  }

  void set spellcheck(bool value) {
     throw new UnsupportedOperationException(
      "Spellcheck can't be set for document fragments.");
  }

  void set tabIndex(int value) {
    throw new UnsupportedOperationException(
      "Tab index can't be set for document fragments.");
  }

  void set title(String value) {
    throw new UnsupportedOperationException(
      "Title can't be set for document fragments.");
  }

  void set webkitdropzone(String value) {
    throw new UnsupportedOperationException(
      "WebKit drop zone can't be set for document fragments.");
  }

  DocumentFragment clone(bool deep) => super.clone(deep);
}

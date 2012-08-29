// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _XMLClassSet extends _CssClassSet {
  _XMLClassSet(element) : super(element);

  String _className() {
    final classStr = _element.getAttribute('class');
    return classStr == null ? '' : classStr;
  }

  void _write(Set s) => _element.setAttribute('class', _formatSet(s));
}

class XMLElementWrappingImplementation extends ElementWrappingImplementation
    implements XMLElement {
  XMLElementWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory XMLElementWrappingImplementation.tag(String tag) =>
    LevelDom.wrapElement(dom.document.createElementNS(null, tag));

  factory XMLElementWrappingImplementation.xml(String xml) {
    XMLElement parentTag = new XMLElement.tag('xml');
    parentTag.innerHTML = xml;
    if (parentTag.nodes.length == 1) return parentTag.nodes.removeLast();

    throw new IllegalArgumentException(
        'XML had ${parentTag.nodes.length} top-level nodes but 1 expected');
  }

  CSSClassSet get classes() {
    if (_cssClassSet === null) {
      _cssClassSet = new _XMLClassSet(_ptr);
    }
    return _cssClassSet;
  }

  ElementList get elements() {
    if (_elements == null) {
      _elements = new FilteredElementList(this);
    }
    return _elements;
  }

  void set elements(Collection<Element> value) {
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  String get outerHTML() {
    final container = new Element.tag("div");
    // Safari requires that the clone be removed from its owner document before
    // being inserted into the HTML document.
    container.elements.add(this.clone(true).remove());
    return container.innerHTML;
  }

  String get innerHTML() {
    final container = new Element.tag("div");
    // Safari requires that the clone be removed from its owner document before
    // being inserted into the HTML document.
    container.nodes.addAll(this.clone(true).remove().nodes);
    return container.innerHTML;
  }

  void set innerHTML(String xml) {
    final xmlDoc = new XMLDocument.xml('<xml>$xml</xml>');
    // Safari requires that the root node be removed from the document before
    // being inserted into the HTML document.
    this.nodes = xmlDoc.remove().nodes;
  }

  Node _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case "beforebegin":
        if (parent == null) return null;
        parent.insertBefore(node, this);
        return node;
      case "afterend":
        if (parent == null) return null;
        if (nextNode == null) {
          parent.nodes.add(node);
        } else {
          parent.insertBefore(node, nextNode);
        }
        return node;
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

  Future<ElementRect> get rect() {
    return _createMeasurementFuture(() => const EmptyElementRect(),
                                    new Completer<ElementRect>());
  }

  // For HTML elemens, the default value of "contentEditable" is "inherit", so
  // we'll use that here as well even though it doesn't really make sense.
  String get contentEditable() => _attr('contentEditable', 'inherit');

  void set contentEditable(String value) {
    attributes['contentEditable'] = value;
  }

  void blur() {}
  void focus() {}
  void scrollByLines([int lines = null]) {}
  void scrollByPages([int pages = null]) {}
  void scrollIntoView([bool centerIfNeeded = null]) {}

  // Parentless HTML elements return false regardless of the value of their
  // contentEditable attribute, so XML elements do the same since they're never
  // actually editable.
  bool get isContentEditable() => false;

  bool get draggable() => attributes['draggable'] == 'true';

  void set draggable(bool value) { attributes['draggable'] = value.toString(); }

  bool get spellcheck() => attributes['spellcheck'] == 'true';

  void set spellcheck(bool value) {
    attributes['spellcheck'] = value.toString();
  }

  bool get hidden() => attributes.containsKey('hidden');

  void set hidden(bool value) {
    if (value) {
      attributes['hidden'] = '';
    } else {
      attributes.remove('hidden');
    }
  }

  int get tabIndex() {
    try {
      return Math.parseInt(_attr('tabIndex'));
    } on FormatException catch (e) {
      return 0;
    }
  }

  void set tabIndex(int value) { attributes['tabIndex'] = value.toString(); }

  String get id() => _attr('id');

  void set id(String value) { attributes['id'] = value; }

  String get title() => _attr('title');

  void set title(String value) { attributes['title'] = value; }

  String get webkitdropzone() => _attr('webkitdropzone');

  void set webkitdropzone(String value) {
    attributes['webkitdropzone'] = value;
  }

  String get lang() => _attr('lang');

  void set lang(String value) { attributes['lang'] = value; }

  String get dir() => _attr('dir');

  void set dir(String value) { attributes['dir'] = value; }

  String _attr(String name, [String def = '']) =>
    attributes.containsKey(name) ? attributes[name] : def;
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SVGElementWrappingImplementation extends ElementWrappingImplementation implements SVGElement {
  SVGElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory SVGElementWrappingImplementation.tag(String tag) =>
    LevelDom.wrapSVGElement(dom.document.createElementNS(
        "http://www.w3.org/2000/svg", tag));

  factory SVGElementWrappingImplementation.svg(String svg) {
    Element parentTag;
    final match = _START_TAG_REGEXP.firstMatch(svg);
    if (match != null && match.group(1).toLowerCase() == 'svg') {
      parentTag = new Element.tag('div');
    } else {
      parentTag = new SVGSVGElement();
    }

    parentTag.innerHTML = svg;
    if (parentTag.elements.length == 1) return parentTag.elements[0];

    throw new IllegalArgumentException('SVG had ${parentTag.elements.length} ' +
        'top-level elements but 1 expected');
  }

  String get id() { return _ptr.id; }

  void set id(String value) { _ptr.id = value; }

  SVGSVGElement get ownerSVGElement() { return LevelDom.wrapSVGSVGElement(_ptr.ownerSVGElement); }

  SVGElement get viewportElement() { return LevelDom.wrapSVGElement(_ptr.viewportElement); }

  String get xmlbase() { return _ptr.xmlbase; }

  void set xmlbase(String value) { _ptr.xmlbase = value; }

  ElementList get elements() {
    if (_elements == null) {
      _elements = new FilteredElementList(this);
    }
    return _elements;
  }

  // TODO: The type of value should be Collection<Element>. See http://b/5392897
  void set elements(value) {
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  String get outerHTML() {
    final container = new Element.tag("div");
    container.elements.add(this.clone(true));
    return container.innerHTML;
  }

  String get innerHTML() {
    final container = new Element.tag("div");
    container.elements.addAll(this.clone(true).dynamic.elements);
    return container.innerHTML;
  }

  void set innerHTML(String svg) {
    var container = new Element.tag("div");
    // Wrap the SVG string in <svg> so that SVGElements are created, rather than
    // HTMLElements.
    container.innerHTML = '<svg version="1.1">$svg</svg>';
    this.elements = container.elements.first.elements;
  }
}

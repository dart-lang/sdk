// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of svg;

final _START_TAG_REGEXP = new RegExp('<(\\w+)');

class _SVGElementFactoryProvider {
  static SVGElement createSVGElement_tag(String tag) {
    final Element temp =
      document.$dom_createElementNS("http://www.w3.org/2000/svg", tag);
    return temp;
  }

  static SVGElement createSVGElement_svg(String svg) {
    Element parentTag;
    final match = _START_TAG_REGEXP.firstMatch(svg);
    if (match != null && match.group(1).toLowerCase() == 'svg') {
      parentTag = new Element.tag('div');
    } else {
      parentTag = new SVGSVGElement();
    }

    parentTag.innerHTML = svg;
    if (parentTag.elements.length == 1) return parentTag.elements.removeLast();

    throw new ArgumentError(
        'SVG had ${parentTag.elements.length} '
        'top-level elements but 1 expected');
  }
}

class _SVGSVGElementFactoryProvider {
  static SVGSVGElement createSVGSVGElement() {
    final el = new SVGElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }
}

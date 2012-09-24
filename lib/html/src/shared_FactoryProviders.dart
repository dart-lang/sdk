// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _EventFactoryProvider {
  static Event createEvent(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final _EventImpl e = _document.$dom_createEvent("Event");
    e.$dom_initEvent(type, canBubble, cancelable);
    return e;
  }
}

class _MouseEventFactoryProvider {
  static MouseEvent createMouseEvent(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = _document.$dom_createEvent("MouseEvent");
    e.$dom_initMouseEvent(type, canBubble, cancelable, view, detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, relatedTarget);
    return e;
  }
}

class _CSSStyleDeclarationFactoryProvider {
  static CSSStyleDeclaration createCSSStyleDeclaration_css(String css) {
    final style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  }

  static CSSStyleDeclaration createCSSStyleDeclaration() {
    return new CSSStyleDeclaration.css('');
  }
}

class _DocumentFragmentFactoryProvider {
  /** @domName Document.createDocumentFragment */
  static DocumentFragment createDocumentFragment() =>
      document.createDocumentFragment();

  static DocumentFragment createDocumentFragment_html(String html) {
    final fragment = new DocumentFragment();
    fragment.innerHTML = html;
    return fragment;
  }

  // TODO(nweiz): enable this when XML is ported.
  // factory DocumentFragment.xml(String xml) {
  //   final fragment = new DocumentFragment();
  //   final e = new XMLElement.tag("xml");
  //   e.innerHTML = xml;
  //
  //   // Copy list first since we don't want liveness during iteration.
  //   final List nodes = new List.from(e.nodes);
  //   fragment.nodes.addAll(nodes);
  //   return fragment;
  // }

  static DocumentFragment createDocumentFragment_svg(String svg) {
    final fragment = new DocumentFragment();
    final e = new SVGSVGElement();
    e.innerHTML = svg;

    // Copy list first since we don't want liveness during iteration.
    final List nodes = new List.from(e.nodes);
    fragment.nodes.addAll(nodes);
    return fragment;
  }
}

class _SVGElementFactoryProvider {
  static SVGElement createSVGElement_tag(String tag) {
    final Element temp =
      _document.$dom_createElementNS("http://www.w3.org/2000/svg", tag);
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
    if (parentTag.elements.length == 1) return parentTag.nodes.removeLast();

    throw new IllegalArgumentException(
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

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _TextFactoryProvider {

  factory Text(String data) => _document._createTextNode(data);
}

class _EventFactoryProvider {
  factory Event(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final _EventImpl e = _document._createEvent("Event");
    e._initEvent(type, canBubble, cancelable);
    return e;
  }
}

class _MouseEventFactoryProvider {
  factory MouseEvent(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = _document._createEvent("MouseEvent");
    e._initMouseEvent(type, canBubble, cancelable, view, detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, relatedTarget);
    return e;
  }
}

class _CSSStyleDeclarationFactoryProvider {
  factory CSSStyleDeclaration.css(String css) {
    final style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  } 

  factory CSSStyleDeclaration() {
    return new CSSStyleDeclaration.css('');
  }
}

final _START_TAG_REGEXP = const RegExp('<(\\w+)');
class _ElementFactoryProvider {
  static final _CUSTOM_PARENT_TAG_MAP = const {
    'body' : 'html',
    'head' : 'html',
    'caption' : 'table',
    'td': 'tr',
    'colgroup': 'table',
    'col' : 'colgroup',
    'tr' : 'tbody',
    'tbody' : 'table',
    'tfoot' : 'table',
    'thead' : 'table',
    'track' : 'audio',
  };

  /** @domName Document.createElement */
  factory Element.html(String html) {
    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detatch the created element from its dummy parent.
    String parentTag = 'div';
    String tag;
    final match = _START_TAG_REGEXP.firstMatch(html);
    if (match !== null) {
      tag = match.group(1).toLowerCase();
      if (_CUSTOM_PARENT_TAG_MAP.containsKey(tag)) {
        parentTag = _CUSTOM_PARENT_TAG_MAP[tag];
      }
    }
    final _ElementImpl temp = new Element.tag(parentTag);
    temp.innerHTML = html;

    Element element;
    if (temp.elements.length == 1) {
      element = temp.elements.first;
    } else if (parentTag == 'html' && temp.elements.length == 2) {
      // Work around for edge case in WebKit and possibly other browsers where
      // both body and head elements are created even though the inner html
      // only contains a head or body element.
      element = temp.elements[tag == 'head' ? 0 : 1];
    } else {
      throw new IllegalArgumentException('HTML had ${temp.elements.length} ' +
          'top level elements but 1 expected');
    }
    element.remove();
    return element;
  }

  /** @domName Document.createElement */
  factory Element.tag(String tag) => _document._createElement(tag);
}

class _DocumentFragmentFactoryProvider {
  /** @domName Document.createDocumentFragment */
  factory DocumentFragment() => document.createDocumentFragment();

  factory DocumentFragment.html(String html) {
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

  factory DocumentFragment.svg(String svg) {
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
  factory SVGElement.tag(String tag) {
    final Element temp =
      _document._createElementNS("http://www.w3.org/2000/svg", tag);
    return temp;
  }

  factory SVGElement.svg(String svg) {
    Element parentTag;
    final match = _START_TAG_REGEXP.firstMatch(svg);
    if (match != null && match.group(1).toLowerCase() == 'svg') {
      parentTag = new Element.tag('div');
    } else {
      parentTag = new SVGSVGElement();
    }

    parentTag.innerHTML = svg;
    if (parentTag.elements.length == 1) return parentTag.nodes.removeLast();

    throw new IllegalArgumentException('SVG had ${parentTag.elements.length} ' +
        'top-level elements but 1 expected');
  }
}

class _SVGSVGElementFactoryProvider {
  factory SVGSVGElement() {
    final el = new SVGElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }
}

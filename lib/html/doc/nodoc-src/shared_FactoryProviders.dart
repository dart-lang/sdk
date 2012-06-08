// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _EventFactoryProvider {
  factory Event(String type, [bool canBubble = true,
                              bool cancelable = true]) => null;
}

class _MouseEventFactoryProvider {
  factory MouseEvent(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
       EventTarget relatedTarget = null]) => null;
}

class _CSSStyleDeclarationFactoryProvider {
  factory CSSStyleDeclaration.css(String css) => null;
  factory CSSStyleDeclaration() => null;
}

class _DocumentFragmentFactoryProvider {
  /** @domName Document.createDocumentFragment */
  factory DocumentFragment() => document.createDocumentFragment();
  factory DocumentFragment.html(String html) => null;
  factory DocumentFragment.xml(String xml) => null;
  factory DocumentFragment.svg(String svg) => null;
}

class _SVGElementFactoryProvider {
  factory SVGElement.tag(String tag) => null;
  factory SVGElement.svg(String svg) => null;
}

class _SVGSVGElementFactoryProvider {
  factory SVGSVGElement() => null;
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

HtmlElement element(CustomElement e) => e.element;

class CustomElement {
  static Expando reverseElements = new Expando();
  static CustomElement reverse(HtmlElement element) => reverseElements[element];

  static List<CustomElement> toBeAttached = <CustomElement>[];
  static void drainAttached() {
    // Send 'attached' to elements that have been attached to the document.
    bool fired = false;
    var connectedElements = toBeAttached
        .where((CustomElement element) => element.element.isConnected)
        .toList();
    for (CustomElement element in connectedElements) {
      toBeAttached.remove(element);
      element.attached();
      fired = true;
    }

    if (toBeAttached.isEmpty) {
      return; // Done.
    }

    if (fired) {
      // The 'attached' events above may have scheduled microtasks that will
      // will add more CustomElements to be document, e.g. 'render'.
      scheduleMicrotask(() => drainAttached());
    }

    while (!toBeAttached.isEmpty) {
      // Either this element will never be attached or it will be attached
      // after a turn of the outer event loop. Fire 'attached' in case it is
      // the latter, since firing it out of order is preferrable to not firing
      // it at all.
      CustomElement element = toBeAttached.removeLast();
      print("Warning: created but not in document: $element");
      element.attached();
    }
  }

  final HtmlElement element;
  CustomElement.created(String elementClass)
      : element = document.createElement("shadow") {
    reverseElements[element] = this;
    element.classes = [elementClass];

    if (toBeAttached.isEmpty) {
      scheduleMicrotask(() => drainAttached());
    }
    toBeAttached.add(this);
  }

  void attached() {}
  void detached() {}

  Element get parent => element.parent;

  List<Element> get children => element.children;
  set children(List<Element> c) => element.children = c;

  CssClassSet get classes => element.classes;
  set classes(dynamic c) => element.classes = c;

  String get title => element.title;
  set title(String t) => element.title = t;

  String get text => element.text;
  set text(String t) => element.text = t;

  CssStyleDeclaration get style => element.style;

  ElementStream<MouseEvent> get onClick => element.onClick;

  Rectangle getBoundingClientRect() => element.getBoundingClientRect();

  List<Node> getElementsByClassName(String c) =>
      element.getElementsByClassName(c);

  void scrollIntoView() => element.scrollIntoView();
}

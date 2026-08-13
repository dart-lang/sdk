// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import 'element_utils.dart';

HTMLElement element(CustomElement e) => e.element;

class CustomElement {
  static Expando reverseElements = new Expando();
  static CustomElement reverse(HTMLElement element) =>
      reverseElements[element] as CustomElement;

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
      // the latter, since firing it out of order is preferable to not firing
      // it at all.
      CustomElement element = toBeAttached.removeLast();
      print("Warning: created but not in document: $element");
      element.attached();
    }
  }

  final HTMLElement element;
  CustomElement.created(String elementClass)
    : element = document.createElement("shadow") as HTMLElement {
    reverseElements[element] = this;
    element.className = elementClass;

    if (toBeAttached.isEmpty) {
      scheduleMicrotask(() => drainAttached());
    }
    toBeAttached.add(this);
  }

  void attached() {}
  void detached() {}

  HTMLElement? get parent => element.parentElement as HTMLElement?;

  List<Node> get children {
    final list = <Node>[];
    for (var i = 0; i < element.children.length; i++) {
      final child = element.children.item(i);
      if (child != null) {
        list.add(child);
      }
    }
    return list;
  }

  set children(List<Node> nodes) {
    element.removeChildren();
    for (var node in nodes) {
      element.appendChild(node);
    }
  }

  CustomElement appendChild(Node node) {
    element.appendChild(node);
    return this;
  }

  CustomElement removeChildren() {
    element.removeChildren();
    return this;
  }

  CustomElement appendChildren(Iterable<Node> nodes) {
    element.appendChildren(nodes);
    return this;
  }

  CustomElement setChildren(Iterable<Node> nodes) {
    element.setChildren(nodes);
    return this;
  }

  String get className => element.className;
  set className(String c) => element.className = c;

  String get title => element.title;
  set title(String t) => element.title = t;

  String get innerText => element.innerText;
  set innerText(String t) => element.innerText = t;

  CSSStyleDeclaration get style => element.style;

  ElementStream<MouseEvent> get onClick => element.onClick;

  DOMRect getBoundingClientRect() => element.getBoundingClientRect();

  HTMLCollection getElementsByClassName(String c) =>
      element.getElementsByClassName(c);

  void scrollIntoView() => element.scrollIntoView();
}

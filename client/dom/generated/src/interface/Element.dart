// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Element extends Node, NodeSelector, ElementTraversal {

  static final int ALLOW_KEYBOARD_INPUT = 1;

  int get childElementCount();

  int get clientHeight();

  int get clientLeft();

  int get clientTop();

  int get clientWidth();

  Element get firstElementChild();

  Element get lastElementChild();

  Element get nextElementSibling();

  int get offsetHeight();

  int get offsetLeft();

  Element get offsetParent();

  int get offsetTop();

  int get offsetWidth();

  Element get previousElementSibling();

  int get scrollHeight();

  int get scrollLeft();

  void set scrollLeft(int value);

  int get scrollTop();

  void set scrollTop(int value);

  int get scrollWidth();

  CSSStyleDeclaration get style();

  String get tagName();

  void blur();

  void focus();

  String getAttribute(String name);

  String getAttributeNS(String namespaceURI, String localName);

  Attr getAttributeNode(String name);

  Attr getAttributeNodeNS(String namespaceURI, String localName);

  ClientRect getBoundingClientRect();

  ClientRectList getClientRects();

  NodeList getElementsByClassName(String name);

  NodeList getElementsByTagName(String name);

  NodeList getElementsByTagNameNS(String namespaceURI, String localName);

  bool hasAttribute(String name);

  bool hasAttributeNS(String namespaceURI, String localName);

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);

  void removeAttribute(String name);

  void removeAttributeNS(String namespaceURI, String localName);

  Attr removeAttributeNode(Attr oldAttr);

  void scrollByLines(int lines);

  void scrollByPages(int pages);

  void scrollIntoView([bool alignWithTop]);

  void scrollIntoViewIfNeeded([bool centerIfNeeded]);

  void setAttribute(String name, String value);

  void setAttributeNS(String namespaceURI, String qualifiedName, String value);

  Attr setAttributeNode(Attr newAttr);

  Attr setAttributeNodeNS(Attr newAttr);

  bool webkitMatchesSelector(String selectors);

  void webkitRequestFullScreen(int flags);
}

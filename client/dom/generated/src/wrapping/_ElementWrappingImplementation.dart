// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ElementWrappingImplementation extends _NodeWrappingImplementation implements Element {
  _ElementWrappingImplementation() : super() {}

  static create__ElementWrappingImplementation() native {
    return new _ElementWrappingImplementation();
  }

  int get childElementCount() { return _get_childElementCount(this); }
  static int _get_childElementCount(var _this) native;

  int get clientHeight() { return _get_clientHeight(this); }
  static int _get_clientHeight(var _this) native;

  int get clientLeft() { return _get_clientLeft(this); }
  static int _get_clientLeft(var _this) native;

  int get clientTop() { return _get_clientTop(this); }
  static int _get_clientTop(var _this) native;

  int get clientWidth() { return _get_clientWidth(this); }
  static int _get_clientWidth(var _this) native;

  Element get firstElementChild() { return _get_firstElementChild(this); }
  static Element _get_firstElementChild(var _this) native;

  Element get lastElementChild() { return _get_lastElementChild(this); }
  static Element _get_lastElementChild(var _this) native;

  Element get nextElementSibling() { return _get_nextElementSibling(this); }
  static Element _get_nextElementSibling(var _this) native;

  int get offsetHeight() { return _get_offsetHeight(this); }
  static int _get_offsetHeight(var _this) native;

  int get offsetLeft() { return _get_offsetLeft(this); }
  static int _get_offsetLeft(var _this) native;

  Element get offsetParent() { return _get_offsetParent(this); }
  static Element _get_offsetParent(var _this) native;

  int get offsetTop() { return _get_offsetTop(this); }
  static int _get_offsetTop(var _this) native;

  int get offsetWidth() { return _get_offsetWidth(this); }
  static int _get_offsetWidth(var _this) native;

  Element get previousElementSibling() { return _get_previousElementSibling(this); }
  static Element _get_previousElementSibling(var _this) native;

  int get scrollHeight() { return _get_scrollHeight(this); }
  static int _get_scrollHeight(var _this) native;

  int get scrollLeft() { return _get_scrollLeft(this); }
  static int _get_scrollLeft(var _this) native;

  void set scrollLeft(int value) { _set_scrollLeft(this, value); }
  static void _set_scrollLeft(var _this, int value) native;

  int get scrollTop() { return _get_scrollTop(this); }
  static int _get_scrollTop(var _this) native;

  void set scrollTop(int value) { _set_scrollTop(this, value); }
  static void _set_scrollTop(var _this, int value) native;

  int get scrollWidth() { return _get_scrollWidth(this); }
  static int _get_scrollWidth(var _this) native;

  CSSStyleDeclaration get style() { return _get_style(this); }
  static CSSStyleDeclaration _get_style(var _this) native;

  String get tagName() { return _get_tagName(this); }
  static String _get_tagName(var _this) native;

  void blur() {
    _blur(this);
    return;
  }
  static void _blur(receiver) native;

  void focus() {
    _focus(this);
    return;
  }
  static void _focus(receiver) native;

  String getAttribute(String name) {
    return _getAttribute(this, name);
  }
  static String _getAttribute(receiver, name) native;

  String getAttributeNS(String namespaceURI, String localName) {
    return _getAttributeNS(this, namespaceURI, localName);
  }
  static String _getAttributeNS(receiver, namespaceURI, localName) native;

  Attr getAttributeNode(String name) {
    return _getAttributeNode(this, name);
  }
  static Attr _getAttributeNode(receiver, name) native;

  Attr getAttributeNodeNS(String namespaceURI, String localName) {
    return _getAttributeNodeNS(this, namespaceURI, localName);
  }
  static Attr _getAttributeNodeNS(receiver, namespaceURI, localName) native;

  ClientRect getBoundingClientRect() {
    return _getBoundingClientRect(this);
  }
  static ClientRect _getBoundingClientRect(receiver) native;

  ClientRectList getClientRects() {
    return _getClientRects(this);
  }
  static ClientRectList _getClientRects(receiver) native;

  NodeList getElementsByClassName(String name) {
    return _getElementsByClassName(this, name);
  }
  static NodeList _getElementsByClassName(receiver, name) native;

  NodeList getElementsByTagName(String name) {
    return _getElementsByTagName(this, name);
  }
  static NodeList _getElementsByTagName(receiver, name) native;

  NodeList getElementsByTagNameNS(String namespaceURI, String localName) {
    return _getElementsByTagNameNS(this, namespaceURI, localName);
  }
  static NodeList _getElementsByTagNameNS(receiver, namespaceURI, localName) native;

  bool hasAttribute(String name) {
    return _hasAttribute(this, name);
  }
  static bool _hasAttribute(receiver, name) native;

  bool hasAttributeNS(String namespaceURI, String localName) {
    return _hasAttributeNS(this, namespaceURI, localName);
  }
  static bool _hasAttributeNS(receiver, namespaceURI, localName) native;

  Element querySelector(String selectors) {
    return _querySelector(this, selectors);
  }
  static Element _querySelector(receiver, selectors) native;

  NodeList querySelectorAll(String selectors) {
    return _querySelectorAll(this, selectors);
  }
  static NodeList _querySelectorAll(receiver, selectors) native;

  void removeAttribute(String name) {
    _removeAttribute(this, name);
    return;
  }
  static void _removeAttribute(receiver, name) native;

  void removeAttributeNS(String namespaceURI, String localName) {
    _removeAttributeNS(this, namespaceURI, localName);
    return;
  }
  static void _removeAttributeNS(receiver, namespaceURI, localName) native;

  Attr removeAttributeNode(Attr oldAttr) {
    return _removeAttributeNode(this, oldAttr);
  }
  static Attr _removeAttributeNode(receiver, oldAttr) native;

  void scrollByLines(int lines) {
    _scrollByLines(this, lines);
    return;
  }
  static void _scrollByLines(receiver, lines) native;

  void scrollByPages(int pages) {
    _scrollByPages(this, pages);
    return;
  }
  static void _scrollByPages(receiver, pages) native;

  void scrollIntoView([bool alignWithTop = null]) {
    if (alignWithTop === null) {
      _scrollIntoView(this);
      return;
    } else {
      _scrollIntoView_2(this, alignWithTop);
      return;
    }
  }
  static void _scrollIntoView(receiver) native;
  static void _scrollIntoView_2(receiver, alignWithTop) native;

  void scrollIntoViewIfNeeded([bool centerIfNeeded = null]) {
    if (centerIfNeeded === null) {
      _scrollIntoViewIfNeeded(this);
      return;
    } else {
      _scrollIntoViewIfNeeded_2(this, centerIfNeeded);
      return;
    }
  }
  static void _scrollIntoViewIfNeeded(receiver) native;
  static void _scrollIntoViewIfNeeded_2(receiver, centerIfNeeded) native;

  void setAttribute(String name, String value) {
    _setAttribute(this, name, value);
    return;
  }
  static void _setAttribute(receiver, name, value) native;

  void setAttributeNS(String namespaceURI, String qualifiedName, String value) {
    _setAttributeNS(this, namespaceURI, qualifiedName, value);
    return;
  }
  static void _setAttributeNS(receiver, namespaceURI, qualifiedName, value) native;

  Attr setAttributeNode(Attr newAttr) {
    return _setAttributeNode(this, newAttr);
  }
  static Attr _setAttributeNode(receiver, newAttr) native;

  Attr setAttributeNodeNS(Attr newAttr) {
    return _setAttributeNodeNS(this, newAttr);
  }
  static Attr _setAttributeNodeNS(receiver, newAttr) native;

  bool webkitMatchesSelector(String selectors) {
    return _webkitMatchesSelector(this, selectors);
  }
  static bool _webkitMatchesSelector(receiver, selectors) native;

  String get typeName() { return "Element"; }
}

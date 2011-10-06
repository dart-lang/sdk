// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NodeWrappingImplementation extends DOMWrapperBase implements Node {
  _NodeWrappingImplementation() : super() {}

  static create__NodeWrappingImplementation() native {
    return new _NodeWrappingImplementation();
  }

  NamedNodeMap get attributes() { return _get__Node_attributes(this); }
  static NamedNodeMap _get__Node_attributes(var _this) native;

  String get baseURI() { return _get__Node_baseURI(this); }
  static String _get__Node_baseURI(var _this) native;

  NodeList get childNodes() { return _get__Node_childNodes(this); }
  static NodeList _get__Node_childNodes(var _this) native;

  Node get firstChild() { return _get__Node_firstChild(this); }
  static Node _get__Node_firstChild(var _this) native;

  Node get lastChild() { return _get__Node_lastChild(this); }
  static Node _get__Node_lastChild(var _this) native;

  String get localName() { return _get__Node_localName(this); }
  static String _get__Node_localName(var _this) native;

  String get namespaceURI() { return _get__Node_namespaceURI(this); }
  static String _get__Node_namespaceURI(var _this) native;

  Node get nextSibling() { return _get__Node_nextSibling(this); }
  static Node _get__Node_nextSibling(var _this) native;

  String get nodeName() { return _get__Node_nodeName(this); }
  static String _get__Node_nodeName(var _this) native;

  int get nodeType() { return _get__Node_nodeType(this); }
  static int _get__Node_nodeType(var _this) native;

  String get nodeValue() { return _get__Node_nodeValue(this); }
  static String _get__Node_nodeValue(var _this) native;

  void set nodeValue(String value) { _set__Node_nodeValue(this, value); }
  static void _set__Node_nodeValue(var _this, String value) native;

  Document get ownerDocument() { return _get__Node_ownerDocument(this); }
  static Document _get__Node_ownerDocument(var _this) native;

  Element get parentElement() { return _get__Node_parentElement(this); }
  static Element _get__Node_parentElement(var _this) native;

  Node get parentNode() { return _get__Node_parentNode(this); }
  static Node _get__Node_parentNode(var _this) native;

  String get prefix() { return _get__Node_prefix(this); }
  static String _get__Node_prefix(var _this) native;

  void set prefix(String value) { _set__Node_prefix(this, value); }
  static void _set__Node_prefix(var _this, String value) native;

  Node get previousSibling() { return _get__Node_previousSibling(this); }
  static Node _get__Node_previousSibling(var _this) native;

  String get textContent() { return _get__Node_textContent(this); }
  static String _get__Node_textContent(var _this) native;

  void set textContent(String value) { _set__Node_textContent(this, value); }
  static void _set__Node_textContent(var _this, String value) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener(this, type, listener);
      return;
    } else {
      _addEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener(receiver, type, listener) native;
  static void _addEventListener_2(receiver, type, listener, useCapture) native;

  Node appendChild(Node newChild) {
    return _appendChild(this, newChild);
  }
  static Node _appendChild(receiver, newChild) native;

  Node cloneNode(bool deep) {
    return _cloneNode(this, deep);
  }
  static Node _cloneNode(receiver, deep) native;

  int compareDocumentPosition(Node other) {
    return _compareDocumentPosition(this, other);
  }
  static int _compareDocumentPosition(receiver, other) native;

  bool contains(Node other) {
    return _contains(this, other);
  }
  static bool _contains(receiver, other) native;

  bool dispatchEvent(Event event) {
    return _dispatchEvent(this, event);
  }
  static bool _dispatchEvent(receiver, event) native;

  bool hasAttributes() {
    return _hasAttributes(this);
  }
  static bool _hasAttributes(receiver) native;

  bool hasChildNodes() {
    return _hasChildNodes(this);
  }
  static bool _hasChildNodes(receiver) native;

  Node insertBefore(Node newChild, Node refChild) {
    return _insertBefore(this, newChild, refChild);
  }
  static Node _insertBefore(receiver, newChild, refChild) native;

  bool isDefaultNamespace(String namespaceURI) {
    return _isDefaultNamespace(this, namespaceURI);
  }
  static bool _isDefaultNamespace(receiver, namespaceURI) native;

  bool isEqualNode(Node other) {
    return _isEqualNode(this, other);
  }
  static bool _isEqualNode(receiver, other) native;

  bool isSameNode(Node other) {
    return _isSameNode(this, other);
  }
  static bool _isSameNode(receiver, other) native;

  bool isSupported(String feature, String version) {
    return _isSupported(this, feature, version);
  }
  static bool _isSupported(receiver, feature, version) native;

  String lookupNamespaceURI(String prefix) {
    return _lookupNamespaceURI(this, prefix);
  }
  static String _lookupNamespaceURI(receiver, prefix) native;

  String lookupPrefix(String namespaceURI) {
    return _lookupPrefix(this, namespaceURI);
  }
  static String _lookupPrefix(receiver, namespaceURI) native;

  void normalize() {
    _normalize(this);
    return;
  }
  static void _normalize(receiver) native;

  Node removeChild(Node oldChild) {
    return _removeChild(this, oldChild);
  }
  static Node _removeChild(receiver, oldChild) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener(this, type, listener);
      return;
    } else {
      _removeEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener(receiver, type, listener) native;
  static void _removeEventListener_2(receiver, type, listener, useCapture) native;

  Node replaceChild(Node newChild, Node oldChild) {
    return _replaceChild(this, newChild, oldChild);
  }
  static Node _replaceChild(receiver, newChild, oldChild) native;

  String get typeName() { return "Node"; }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _RangeWrappingImplementation extends DOMWrapperBase implements Range {
  _RangeWrappingImplementation() : super() {}

  static create__RangeWrappingImplementation() native {
    return new _RangeWrappingImplementation();
  }

  bool get collapsed() { return _get_collapsed(this); }
  static bool _get_collapsed(var _this) native;

  Node get commonAncestorContainer() { return _get_commonAncestorContainer(this); }
  static Node _get_commonAncestorContainer(var _this) native;

  Node get endContainer() { return _get_endContainer(this); }
  static Node _get_endContainer(var _this) native;

  int get endOffset() { return _get_endOffset(this); }
  static int _get_endOffset(var _this) native;

  Node get startContainer() { return _get_startContainer(this); }
  static Node _get_startContainer(var _this) native;

  int get startOffset() { return _get_startOffset(this); }
  static int _get_startOffset(var _this) native;

  DocumentFragment cloneContents() {
    return _cloneContents(this);
  }
  static DocumentFragment _cloneContents(receiver) native;

  Range cloneRange() {
    return _cloneRange(this);
  }
  static Range _cloneRange(receiver) native;

  void collapse(bool toStart) {
    _collapse(this, toStart);
    return;
  }
  static void _collapse(receiver, toStart) native;

  int compareNode(Node refNode) {
    return _compareNode(this, refNode);
  }
  static int _compareNode(receiver, refNode) native;

  int comparePoint(Node refNode, int offset) {
    return _comparePoint(this, refNode, offset);
  }
  static int _comparePoint(receiver, refNode, offset) native;

  DocumentFragment createContextualFragment(String html) {
    return _createContextualFragment(this, html);
  }
  static DocumentFragment _createContextualFragment(receiver, html) native;

  void deleteContents() {
    _deleteContents(this);
    return;
  }
  static void _deleteContents(receiver) native;

  void detach() {
    _detach(this);
    return;
  }
  static void _detach(receiver) native;

  void expand(String unit) {
    _expand(this, unit);
    return;
  }
  static void _expand(receiver, unit) native;

  DocumentFragment extractContents() {
    return _extractContents(this);
  }
  static DocumentFragment _extractContents(receiver) native;

  ClientRect getBoundingClientRect() {
    return _getBoundingClientRect(this);
  }
  static ClientRect _getBoundingClientRect(receiver) native;

  ClientRectList getClientRects() {
    return _getClientRects(this);
  }
  static ClientRectList _getClientRects(receiver) native;

  void insertNode(Node newNode) {
    _insertNode(this, newNode);
    return;
  }
  static void _insertNode(receiver, newNode) native;

  bool intersectsNode(Node refNode) {
    return _intersectsNode(this, refNode);
  }
  static bool _intersectsNode(receiver, refNode) native;

  bool isPointInRange(Node refNode, int offset) {
    return _isPointInRange(this, refNode, offset);
  }
  static bool _isPointInRange(receiver, refNode, offset) native;

  void selectNode(Node refNode) {
    _selectNode(this, refNode);
    return;
  }
  static void _selectNode(receiver, refNode) native;

  void selectNodeContents(Node refNode) {
    _selectNodeContents(this, refNode);
    return;
  }
  static void _selectNodeContents(receiver, refNode) native;

  void setEnd(Node refNode, int offset) {
    _setEnd(this, refNode, offset);
    return;
  }
  static void _setEnd(receiver, refNode, offset) native;

  void setEndAfter(Node refNode) {
    _setEndAfter(this, refNode);
    return;
  }
  static void _setEndAfter(receiver, refNode) native;

  void setEndBefore(Node refNode) {
    _setEndBefore(this, refNode);
    return;
  }
  static void _setEndBefore(receiver, refNode) native;

  void setStart(Node refNode, int offset) {
    _setStart(this, refNode, offset);
    return;
  }
  static void _setStart(receiver, refNode, offset) native;

  void setStartAfter(Node refNode) {
    _setStartAfter(this, refNode);
    return;
  }
  static void _setStartAfter(receiver, refNode) native;

  void setStartBefore(Node refNode) {
    _setStartBefore(this, refNode);
    return;
  }
  static void _setStartBefore(receiver, refNode) native;

  void surroundContents(Node newParent) {
    _surroundContents(this, newParent);
    return;
  }
  static void _surroundContents(receiver, newParent) native;

  String toString() {
    return _toString(this);
  }
  static String _toString(receiver) native;

  String get typeName() { return "Range"; }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TreeWalkerWrappingImplementation extends DOMWrapperBase implements TreeWalker {
  _TreeWalkerWrappingImplementation() : super() {}

  static create__TreeWalkerWrappingImplementation() native {
    return new _TreeWalkerWrappingImplementation();
  }

  Node get currentNode() { return _get_currentNode(this); }
  static Node _get_currentNode(var _this) native;

  void set currentNode(Node value) { _set_currentNode(this, value); }
  static void _set_currentNode(var _this, Node value) native;

  bool get expandEntityReferences() { return _get_expandEntityReferences(this); }
  static bool _get_expandEntityReferences(var _this) native;

  NodeFilter get filter() { return _get_filter(this); }
  static NodeFilter _get_filter(var _this) native;

  Node get root() { return _get_root(this); }
  static Node _get_root(var _this) native;

  int get whatToShow() { return _get_whatToShow(this); }
  static int _get_whatToShow(var _this) native;

  Node firstChild() {
    return _firstChild(this);
  }
  static Node _firstChild(receiver) native;

  Node lastChild() {
    return _lastChild(this);
  }
  static Node _lastChild(receiver) native;

  Node nextNode() {
    return _nextNode(this);
  }
  static Node _nextNode(receiver) native;

  Node nextSibling() {
    return _nextSibling(this);
  }
  static Node _nextSibling(receiver) native;

  Node parentNode() {
    return _parentNode(this);
  }
  static Node _parentNode(receiver) native;

  Node previousNode() {
    return _previousNode(this);
  }
  static Node _previousNode(receiver) native;

  Node previousSibling() {
    return _previousSibling(this);
  }
  static Node _previousSibling(receiver) native;

  String get typeName() { return "TreeWalker"; }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RangeWrappingImplementation extends DOMWrapperBase implements Range {
  RangeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get collapsed() { return _ptr.collapsed; }

  Node get commonAncestorContainer() { return LevelDom.wrapNode(_ptr.commonAncestorContainer); }

  Node get endContainer() { return LevelDom.wrapNode(_ptr.endContainer); }

  int get endOffset() { return _ptr.endOffset; }

  Node get startContainer() { return LevelDom.wrapNode(_ptr.startContainer); }

  int get startOffset() { return _ptr.startOffset; }

  String get text() { return _ptr.text; }

  DocumentFragment cloneContents() {
    return LevelDom.wrapDocumentFragment(_ptr.cloneContents());
  }

  Range cloneRange() {
    return LevelDom.wrapRange(_ptr.cloneRange());
  }

  void collapse(bool toStart) {
    _ptr.collapse(toStart);
    return;
  }

  int compareNode(Node refNode) {
    return _ptr.compareNode(LevelDom.unwrap(refNode));
  }

  int comparePoint(Node refNode, int offset) {
    return _ptr.comparePoint(LevelDom.unwrap(refNode), offset);
  }

  DocumentFragment createContextualFragment(String html) {
    return LevelDom.wrapDocumentFragment(_ptr.createContextualFragment(html));
  }

  void deleteContents() {
    _ptr.deleteContents();
    return;
  }

  void detach() {
    _ptr.detach();
    return;
  }

  void expand(String unit) {
    _ptr.expand(unit);
    return;
  }

  DocumentFragment extractContents() {
    return LevelDom.wrapDocumentFragment(_ptr.extractContents());
  }

  void insertNode(Node newNode) {
    _ptr.insertNode(LevelDom.unwrap(newNode));
    return;
  }

  bool intersectsNode(Node refNode) {
    return _ptr.intersectsNode(LevelDom.unwrap(refNode));
  }

  bool isPointInRange(Node refNode, int offset) {
    return _ptr.isPointInRange(LevelDom.unwrap(refNode), offset);
  }

  void selectNode(Node refNode) {
    _ptr.selectNode(LevelDom.unwrap(refNode));
    return;
  }

  void selectNodeContents(Node refNode) {
    _ptr.selectNodeContents(LevelDom.unwrap(refNode));
    return;
  }

  void setEnd(Node refNode, int offset) {
    _ptr.setEnd(LevelDom.unwrap(refNode), offset);
    return;
  }

  void setEndAfter(Node refNode) {
    _ptr.setEndAfter(LevelDom.unwrap(refNode));
    return;
  }

  void setEndBefore(Node refNode) {
    _ptr.setEndBefore(LevelDom.unwrap(refNode));
    return;
  }

  void setStart(Node refNode, int offset) {
    _ptr.setStart(LevelDom.unwrap(refNode), offset);
    return;
  }

  void setStartAfter(Node refNode) {
    _ptr.setStartAfter(LevelDom.unwrap(refNode));
    return;
  }

  void setStartBefore(Node refNode) {
    _ptr.setStartBefore(LevelDom.unwrap(refNode));
    return;
  }

  void surroundContents(Node newParent) {
    _ptr.surroundContents(LevelDom.unwrap(newParent));
    return;
  }

  String toString() {
    return _ptr.toString();
  }
}

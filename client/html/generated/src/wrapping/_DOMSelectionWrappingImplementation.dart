// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMSelectionWrappingImplementation extends DOMWrapperBase implements DOMSelection {
  DOMSelectionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Node get anchorNode() { return LevelDom.wrapNode(_ptr.anchorNode); }

  int get anchorOffset() { return _ptr.anchorOffset; }

  Node get baseNode() { return LevelDom.wrapNode(_ptr.baseNode); }

  int get baseOffset() { return _ptr.baseOffset; }

  Node get extentNode() { return LevelDom.wrapNode(_ptr.extentNode); }

  int get extentOffset() { return _ptr.extentOffset; }

  Node get focusNode() { return LevelDom.wrapNode(_ptr.focusNode); }

  int get focusOffset() { return _ptr.focusOffset; }

  bool get isCollapsed() { return _ptr.isCollapsed; }

  int get rangeCount() { return _ptr.rangeCount; }

  String get type() { return _ptr.type; }

  void addRange(Range range) {
    _ptr.addRange(LevelDom.unwrap(range));
    return;
  }

  void collapse(Node node, int index) {
    _ptr.collapse(LevelDom.unwrap(node), index);
    return;
  }

  void collapseToEnd() {
    _ptr.collapseToEnd();
    return;
  }

  void collapseToStart() {
    _ptr.collapseToStart();
    return;
  }

  bool containsNode(Node node, bool allowPartial) {
    return _ptr.containsNode(LevelDom.unwrap(node), allowPartial);
  }

  void deleteFromDocument() {
    _ptr.deleteFromDocument();
    return;
  }

  void empty() {
    _ptr.empty();
    return;
  }

  void extend(Node node, int offset) {
    _ptr.extend(LevelDom.unwrap(node), offset);
    return;
  }

  Range getRangeAt(int index) {
    return LevelDom.wrapRange(_ptr.getRangeAt(index));
  }

  void modify(String alter, String direction, String granularity) {
    _ptr.modify(alter, direction, granularity);
    return;
  }

  void removeAllRanges() {
    _ptr.removeAllRanges();
    return;
  }

  void selectAllChildren(Node node) {
    _ptr.selectAllChildren(LevelDom.unwrap(node));
    return;
  }

  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) {
    _ptr.setBaseAndExtent(LevelDom.unwrap(baseNode), baseOffset, LevelDom.unwrap(extentNode), extentOffset);
    return;
  }

  void setPosition(Node node, int offset) {
    _ptr.setPosition(LevelDom.unwrap(node), offset);
    return;
  }
}

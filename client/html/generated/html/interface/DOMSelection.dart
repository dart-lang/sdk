// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMSelection {

  final Node anchorNode;

  final int anchorOffset;

  final Node baseNode;

  final int baseOffset;

  final Node extentNode;

  final int extentOffset;

  final Node focusNode;

  final int focusOffset;

  final bool isCollapsed;

  final int rangeCount;

  final String type;

  void addRange(Range range);

  void collapse(Node node, int index);

  void collapseToEnd();

  void collapseToStart();

  bool containsNode(Node node, bool allowPartial);

  void deleteFromDocument();

  void empty();

  void extend(Node node, int offset);

  Range getRangeAt(int index);

  void modify(String alter, String direction, String granularity);

  void removeAllRanges();

  void selectAllChildren(Node node);

  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset);

  void setPosition(Node node, int offset);

  String toString();
}

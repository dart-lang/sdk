// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Selection {

  Node get anchorNode();

  int get anchorOffset();

  Node get baseNode();

  int get baseOffset();

  Node get extentNode();

  int get extentOffset();

  Node get focusNode();

  int get focusOffset();

  bool get isCollapsed();

  int get rangeCount();

  String get type();

  void addRange(Range range = null);

  void collapse(Node node = null, int index = null);

  void collapseToEnd();

  void collapseToStart();

  bool containsNode(Node node = null, bool allowPartial = null);

  void deleteFromDocument();

  void empty();

  void extend(Node node = null, int offset = null);

  Range getRangeAt(int index = null);

  void modify(String alter = null, String direction = null, String granularity = null);

  void removeAllRanges();

  void selectAllChildren(Node node = null);

  void setBaseAndExtent(Node baseNode = null, int baseOffset = null, Node extentNode = null, int extentOffset = null);

  void setPosition(Node node = null, int offset = null);
}

interface DOMSelection extends Selection {
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Range {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  bool get collapsed();

  Node get commonAncestorContainer();

  Node get endContainer();

  int get endOffset();

  Node get startContainer();

  int get startOffset();

  String get text();

  DocumentFragment cloneContents();

  Range cloneRange();

  void collapse(bool toStart);

  int compareBoundaryPoints();

  int compareNode(Node refNode);

  int comparePoint(Node refNode, int offset);

  DocumentFragment createContextualFragment(String html);

  void deleteContents();

  void detach();

  void expand(String unit);

  DocumentFragment extractContents();

  void insertNode(Node newNode);

  bool intersectsNode(Node refNode);

  bool isPointInRange(Node refNode, int offset);

  void selectNode(Node refNode);

  void selectNodeContents(Node refNode);

  void setEnd(Node refNode, int offset);

  void setEndAfter(Node refNode);

  void setEndBefore(Node refNode);

  void setStart(Node refNode, int offset);

  void setStartAfter(Node refNode);

  void setStartBefore(Node refNode);

  void surroundContents(Node newParent);

  String toString();
}

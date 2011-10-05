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

  void collapse(bool toStart = null);

  int compareBoundaryPoints();

  int compareNode(Node refNode = null);

  int comparePoint(Node refNode = null, int offset = null);

  DocumentFragment createContextualFragment(String html = null);

  void deleteContents();

  void detach();

  void expand(String unit = null);

  DocumentFragment extractContents();

  void insertNode(Node newNode = null);

  bool intersectsNode(Node refNode = null);

  bool isPointInRange(Node refNode = null, int offset = null);

  void selectNode(Node refNode = null);

  void selectNodeContents(Node refNode = null);

  void setEnd(Node refNode = null, int offset = null);

  void setEndAfter(Node refNode = null);

  void setEndBefore(Node refNode = null);

  void setStart(Node refNode = null, int offset = null);

  void setStartAfter(Node refNode = null);

  void setStartBefore(Node refNode = null);

  void surroundContents(Node newParent = null);

  String toString();
}

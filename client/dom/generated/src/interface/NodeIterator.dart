// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeIterator {

  bool get expandEntityReferences();

  NodeFilter get filter();

  bool get pointerBeforeReferenceNode();

  Node get referenceNode();

  Node get root();

  int get whatToShow();

  void detach();

  Node nextNode();

  Node previousNode();
}

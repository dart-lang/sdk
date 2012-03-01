// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeIterator {

  final bool expandEntityReferences;

  final NodeFilter filter;

  final bool pointerBeforeReferenceNode;

  final Node referenceNode;

  final Node root;

  final int whatToShow;

  void detach();

  Node nextNode();

  Node previousNode();
}

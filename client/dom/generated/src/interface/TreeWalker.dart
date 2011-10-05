// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TreeWalker {

  Node get currentNode();

  void set currentNode(Node value);

  bool get expandEntityReferences();

  NodeFilter get filter();

  Node get root();

  int get whatToShow();

  Node firstChild();

  Node lastChild();

  Node nextNode();

  Node nextSibling();

  Node parentNode();

  Node previousNode();

  Node previousSibling();
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of tree;

/**
 * This visitor takes another visitor and applies it to every
 * node in the tree. There is currently no way to control the
 * traversal.
 */
class TraversingVisitor extends Visitor {
  final Visitor visitor;

  TraversingVisitor(Visitor this.visitor);

  visitNode(Node node) {
    node.accept(visitor);
    node.visitChildren(this);
  }
}

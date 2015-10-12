// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cps_ir.parent_visitor;

import 'cps_ir_nodes.dart';

/// Traverses the CPS term and sets node.parent for each visited node.
class ParentVisitor extends DeepRecursiveVisitor {
  static void setParents(Node node) {
    ParentVisitor visitor = new ParentVisitor._make();
    visitor._worklist.add(node);
    visitor.trampoline();
  }

  /// Private to avoid accidental `new ParentVisitor().visit(node)` calls.
  ParentVisitor._make();

  Node _parent;
  final List<Node> _worklist = <Node>[];

  void trampoline() {
    while (_worklist.isNotEmpty) {
      _parent = _worklist.removeLast();
      _parent.accept(this);
    }
  }

  @override
  visit(Node node) {
    _worklist.add(node);
    assert(_parent != node);
    assert(_parent != null);
    node.parent = _parent;
  }

  @override
  processReference(Reference node) {
    node.parent = _parent;
  }
}


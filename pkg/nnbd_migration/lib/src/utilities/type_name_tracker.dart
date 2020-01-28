// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// A simple class to find all [TypeName]s and track if they all get visited.
class TypeNameTracker extends RecursiveAstVisitor<void> {
  final Set<TypeName> _nodes = {};

  bool _isTrueTypeName(TypeName node) {
    final parent = node.parent;
    if (parent is ConstructorName) {
      // We only need to visit C in `new C()`, just `int` in `new C<int>()`.
      return parent.type != node;
    }

    return true;
  }

  @override
  void visitTypeName(TypeName node) {
    if (_isTrueTypeName(node)) {
      _nodes.add(node);
    }
    super.visitTypeName(node);
  }

  void nodeVisited(TypeName node) {
    if (_isTrueTypeName(node) && !_nodes.remove(node)) {
      throw StateError('Visited unexpected type name $node');
    }
  }

  void finalize() {
    assert(_nodes.isEmpty, 'Annotation nodes not visited: $_nodes');
  }
}

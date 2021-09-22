// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// A simple class to find all [NamedType]s and track if they all get visited.
class NamedTypeTracker extends RecursiveAstVisitor<void> {
  final Set<NamedType> _nodes = {};

  void finalize() {
    assert(_nodes.isEmpty, 'Annotation nodes not visited: $_nodes');
  }

  void nodeVisited(NamedType node) {
    if (_isTrueNamedType(node) && !_nodes.remove(node)) {
      throw StateError('Visited unexpected type name $node');
    }
  }

  @override
  void visitNamedType(NamedType node) {
    if (_isTrueNamedType(node)) {
      _nodes.add(node);
    }
    super.visitNamedType(node);
  }

  bool _isTrueNamedType(NamedType node) {
    final parent = node.parent;
    if (parent is ConstructorName) {
      // We only need to visit C in `new C()`, just `int` in `new C<int>()`.
      return parent.type2 != node;
    }

    return true;
  }
}

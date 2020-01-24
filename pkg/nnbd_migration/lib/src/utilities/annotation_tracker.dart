// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// A simple class to find all [Annotation]s and track if they all get visited.
class AnnotationTracker extends RecursiveAstVisitor<void> {
  final Set<Annotation> _nodes = {};

  @override
  void visitAnnotation(Annotation node) {
    _nodes.add(node);
  }

  void nodeVisited(Annotation node) {
    if (!_nodes.remove(node)) {
      throw StateError('Visited unexpected annotation $node');
    }
  }

  void finalize() {
    assert(_nodes.isEmpty, 'Annotation nodes not visited: $_nodes');
  }
}

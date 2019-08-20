// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';

/// Mixin that verifies (via assertion checks) that a visitor does not miss any
/// annotations when processing a compilation unit.
///
/// Mixing in this class should have very low overhead when assertions are
/// disabled.
mixin AnnotationTracker<T> on AstVisitor<T>, PermissiveModeVisitor<T> {
  static _AnnotationTracker _annotationTracker;

  @override
  T visitAnnotation(Annotation node) {
    assert(() {
      _annotationTracker._nodeVisited(node);
      return true;
    }());
    return super.visitAnnotation(node);
  }

  @override
  T visitCompilationUnit(CompilationUnit node) {
    T result;
    reportExceptionsIfPermissive(node, () {
      _AnnotationTracker oldAnnotationTracker;
      assert(() {
        oldAnnotationTracker = _annotationTracker;
        _annotationTracker = _AnnotationTracker();
        node.accept(_annotationTracker);
        return true;
      }());
      try {
        result = super.visitCompilationUnit(node);
        assert(_annotationTracker._nodes.isEmpty,
            'Annotation nodes not visited: ${_annotationTracker._nodes}');
      } finally {
        _annotationTracker = oldAnnotationTracker;
      }
    });
    return result;
  }
}

class _AnnotationTracker extends RecursiveAstVisitor<void> {
  final Set<Annotation> _nodes = {};

  @override
  void visitAnnotation(Annotation node) {
    _nodes.add(node);
  }

  void _nodeVisited(Annotation node) {
    if (!_nodes.remove(node)) {
      throw StateError('Visited unexpected annotation $node');
    }
  }
}

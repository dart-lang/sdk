// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';
import 'package:nnbd_migration/src/utilities/annotation_tracker.dart';
import 'package:nnbd_migration/src/utilities/type_name_tracker.dart';

/// Mixin that verifies (via assertion checks) that a visitor visits a
/// compilation unit to "completeness" -- currently tracks Annotations and
/// TypeNames.
///
/// Mixing in this class should have very low overhead when assertions are
/// disabled.
mixin CompletenessTracker<T> on AstVisitor<T>, PermissiveModeVisitor<T> {
  AnnotationTracker _annotationTracker;
  TypeNameTracker _typeNameTracker;

  @override
  T visitAnnotation(Annotation node) {
    annotationVisited(node);
    return super.visitAnnotation(node);
  }

  void annotationVisited(Annotation node) {
    assert(() {
      _annotationTracker.nodeVisited(node);
      return true;
    }());
  }

  void typeNameVisited(TypeName node) {
    assert(() {
      _typeNameTracker.nodeVisited(node);
      return true;
    }());
  }

  @override
  T visitCompilationUnit(CompilationUnit node) {
    T result;
    reportExceptionsIfPermissive(node, () {
      assert(() {
        assert(_annotationTracker == null);
        assert(_typeNameTracker == null);
        _annotationTracker = AnnotationTracker()..visitCompilationUnit(node);
        _typeNameTracker = TypeNameTracker()..visitCompilationUnit(node);
        return true;
      }());
      try {
        result = super.visitCompilationUnit(node);
        assert(() {
          _annotationTracker.finalize();
          _typeNameTracker.finalize();
          return true;
        }());
      } finally {
        _annotationTracker = null;
        _typeNameTracker = null;
      }
    });
    return result;
  }
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:nnbd_migration/src/utilities/annotation_tracker.dart';
import 'package:nnbd_migration/src/utilities/named_type_tracker.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';

/// Mixin that verifies (via assertion checks) that a visitor visits a
/// compilation unit to "completeness" -- currently tracks Annotations and
/// TypeNames.
///
/// Mixing in this class should have very low overhead when assertions are
/// disabled.
mixin CompletenessTracker<T> on AstVisitor<T>, PermissiveModeVisitor<T> {
  AnnotationTracker? _annotationTracker;
  NamedTypeTracker? _namedTypeTracker;

  void annotationVisited(Annotation node) {
    assert(() {
      _annotationTracker!.nodeVisited(node);
      return true;
    }());
  }

  void namedTypeVisited(NamedType node) {
    assert(() {
      _namedTypeTracker!.nodeVisited(node);
      return true;
    }());
  }

  @override
  T? visitAnnotation(Annotation node) {
    annotationVisited(node);
    return super.visitAnnotation(node);
  }

  @override
  T? visitCompilationUnit(CompilationUnit node) {
    T? result;
    reportExceptionsIfPermissive(node, () {
      assert(() {
        assert(_annotationTracker == null);
        assert(_namedTypeTracker == null);
        _annotationTracker = AnnotationTracker()..visitCompilationUnit(node);
        _namedTypeTracker = NamedTypeTracker()..visitCompilationUnit(node);
        return true;
      }());
      try {
        result = super.visitCompilationUnit(node);
        assert(() {
          _annotationTracker!.finalize();
          _namedTypeTracker!.finalize();
          return true;
        }());
      } finally {
        _annotationTracker = null;
        _namedTypeTracker = null;
      }
    });
    return result;
  }
}

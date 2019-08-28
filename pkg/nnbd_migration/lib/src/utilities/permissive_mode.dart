// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:nnbd_migration/nnbd_migration.dart';

/// Mixin that catches exceptions when visiting an AST recursively, and reports
/// them to an optional listener.  This is used to implement the migration
/// tool's "permissive mode".
///
/// If the [listener] is `null`, exceptions are not caught.
mixin PermissiveModeVisitor<T> on GeneralizingAstVisitor<T> {
  NullabilityMigrationListener /*?*/ get listener;

  /// Executes [callback].  If [listener] is not `null`, and an exception
  /// occurs, the exception is caught and reported to the [listener].
  void reportExceptionsIfPermissive(void callback()) {
    if (listener != null) {
      try {
        return callback();
      } catch (exception, stackTrace) {
        _reportException(exception, stackTrace);
      }
    } else {
      callback();
    }
  }

  @override
  T visitNode(AstNode node) {
    if (listener != null) {
      try {
        return super.visitNode(node);
      } catch (exception, stackTrace) {
        _reportException(exception, stackTrace);
        return null;
      }
    } else {
      return super.visitNode(node);
    }
  }

  void _reportException(Object exception, StackTrace stackTrace) {
    listener.addDetail('''
$exception

$stackTrace''');
  }
}

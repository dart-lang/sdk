// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' show DartType;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

/// Abstract implementation of type inference which is independent of the
/// underlying AST representation (but still uses DartType from kernel).
///
/// TODO(paulberry): would it make more sense to abstract away the
/// representation of types as well?
///
/// Derived classes should set S, E, V, and F to the class they use to represent
/// statements, expressions, variable declarations, and field declarations,
/// respectively.
abstract class TypeInferrer<S, E, V, F> {
  final CoreTypes coreTypes;

  final ClassHierarchy classHierarchy;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  Uri uri;

  TypeInferrer(this.coreTypes, this.classHierarchy);

  /// Performs type inference on a method with the given method [body].
  ///
  /// [uri] is the URI of the file the method is contained in--this is used for
  /// testing.
  void inferBody(S body, Uri uri) {
    this.uri = uri;
    inferStatement(body);
  }

  /// Performs type inference on the given [expression].
  ///
  /// [typeContext] is the expected type of the expression, based on surrounding
  /// code.  [typeNeeded] indicates whether it is necessary to compute the
  /// actual type of the expression.  If [typeNeeded] is `true`, the actual type
  /// of the expression is returned; otherwise `null` is returned.
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the expression type and calls the appropriate specialized "infer" method.
  DartType inferExpression(E expression, DartType typeContext, bool typeNeeded);

  /// Performs type inference on the given [statement].
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the statement type and calls the appropriate specialized "infer" method.
  void inferStatement(S statement);
}

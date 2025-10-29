// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/ast_to_ir_types.dart' show AstToIrTypes;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart'
    show StaticTypeContext, TypeEnvironment;
import 'package:meta/meta.dart';

/// Collection of singleton objects, globally available
/// during compilation.
///
/// Each object should be initialized before use
/// (either when the context is created or lazily).
class GlobalContext {
  /// Front-end type environment.
  ///
  /// Provides access to [CoreTypes], [ClassHierarchy] and
  /// implements operations on Dart static types, such as a subtype test.
  final TypeEnvironment typeEnvironment;

  /// Create a new context.
  GlobalContext({required this.typeEnvironment});

  /// AST nodes of core libraries, classes and members.
  CoreTypes get coreTypes => typeEnvironment.coreTypes;

  /// Front-end class hierarchy.
  ClassHierarchy get classHierarchy => typeEnvironment.hierarchy;

  /// Front-end static type context for computation of
  /// static types of constants.
  late final StaticTypeContext staticTypeContextForConstants =
      StaticTypeContext(
        coreTypes.identicalProcedure /* arbitrary top-level function */,
        typeEnvironment,
      );

  /// Translation of Dart static types into CFG IR types.
  late final AstToIrTypes astToIrTypes = AstToIrTypes(
    coreTypes,
    classHierarchy,
  );

  static GlobalContext? _instance;

  /// Current instance of [GlobalContext].
  static GlobalContext get instance =>
      _instance ?? (throw StateError('GlobalContext is not set'));

  /// Call [action] with [context] used as the current instance of [GlobalContext] and return its result.
  static T withContext<T>(GlobalContext context, T Function() action) {
    final savedContext = _instance;
    _instance = context;
    try {
      return action();
    } finally {
      _instance = savedContext;
    }
  }

  /// Set given [context] as the current instance of [GlobalContext].
  ///
  /// This method is unsafe as caller is responsible for saving
  /// and restoring current context manually.
  /// So, this method is intended to be used only in unit test.
  @visibleForTesting
  static void setCurrentContext(GlobalContext? context) {
    _instance = context;
  }
}

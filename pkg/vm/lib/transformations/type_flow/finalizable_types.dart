// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/type_environment.dart';
import 'package:vm/modular/transformations/ffi/finalizable.dart'
    show FinalizableDartType;

/// Provides insights into `Finalizable`s.
class FinalizableTypes {
  final TypeEnvironment _env;
  final Class _finalizableClass;

  FinalizableTypes(
    CoreTypes coreTypes,
    LibraryIndex index,
    ClassHierarchy classHierarchy,
  )   : _env = TypeEnvironment(coreTypes, classHierarchy),
        _finalizableClass = index.getClass('dart:ffi', 'Finalizable');

  bool isFieldFinalizable(Field field) => _isFinalizable(field.type);

  /// Cache for [_isFinalizable].
  Map<DartType, bool> _isFinalizableCache = {};

  /// Whether [type] is something that subtypes `FutureOr<Finalizable?>?`.
  bool _isFinalizable(DartType type) => type.isFinalizable(
        finalizableClass: _finalizableClass,
        typeEnvironment: _env,
        cache: _isFinalizableCache,
      );
}

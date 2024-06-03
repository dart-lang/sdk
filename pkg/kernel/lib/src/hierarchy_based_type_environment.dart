// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.hierarchy_based_type_environment;

import '../ast.dart' show DartType, TypeDeclaration, TypeDeclarationType;

import '../class_hierarchy.dart' show ClassHierarchy;

import '../core_types.dart' show CoreTypes;

import '../type_environment.dart' show TypeEnvironment;

class HierarchyBasedTypeEnvironment extends TypeEnvironment {
  @override
  final ClassHierarchy hierarchy;

  HierarchyBasedTypeEnvironment(CoreTypes coreTypes, this.hierarchy)
      : super.fromSubclass(coreTypes, hierarchy);

  @override
  TypeDeclarationType? getTypeAsInstanceOf(TypeDeclarationType type,
      TypeDeclaration typeDeclaration, CoreTypes coreTypes) {
    return hierarchy.getTypeAsInstanceOf(type, typeDeclaration);
  }

  @override
  List<DartType>? getTypeArgumentsAsInstanceOf(
      TypeDeclarationType type, TypeDeclaration typeDeclaration) {
    if (type.typeDeclaration == typeDeclaration) return type.typeArguments;
    return hierarchy.getTypeArgumentsAsInstanceOf(type, typeDeclaration);
  }
}
